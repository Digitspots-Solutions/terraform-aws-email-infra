# =============================================================================
# TERRAFORM AWS EMAIL INFRASTRUCTURE MODULE
# =============================================================================
# 
# A reusable module for setting up AWS WorkMail with Route53 DNS verification.
# 
# Usage:
#   module "email" {
#     source = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"
#     
#     domain_name       = "example.com"
#     workmail_user     = "info"
#     workmail_password = var.password
#   }
#
# =============================================================================

locals {
  # Extract domain without TLD for cleaner alias
  domain_parts    = split(".", var.domain_name)
  workmail_alias  = local.domain_parts[0]
  
  # Construct the final email address
  email_address = "${var.workmail_user}@${var.domain_name}"
}

# =============================================================================
# 1. Route 53 Zone Lookup
# =============================================================================
data "aws_route53_zone" "this" {
  name = var.domain_name
}

# =============================================================================
# 2. WorkMail Organization - Get or Create
# =============================================================================
data "external" "workmail_org" {
  count = var.workmail_org_id == null ? 1 : 0

  program = ["bash", "${path.module}/scripts/workmail_org.sh"]

  query = {
    alias   = local.workmail_alias
    region  = var.workmail_region
    profile = var.aws_profile != null ? var.aws_profile : ""
  }
}

locals {
  effective_org_id = var.workmail_org_id != null ? var.workmail_org_id : data.external.workmail_org[0].result.org_id
}

# =============================================================================
# 3. Register Domain with WorkMail & Get DNS Records
# =============================================================================
data "external" "workmail_domain" {
  program = ["bash", "${path.module}/scripts/workmail_domain.sh"]

  query = {
    org_id  = local.effective_org_id
    domain  = var.domain_name
    region  = var.workmail_region
    profile = var.aws_profile != null ? var.aws_profile : ""
  }

  depends_on = [data.external.workmail_org]
}

# =============================================================================
# 4. DNS Verification Records
# =============================================================================
resource "aws_route53_record" "workmail_txt" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.external.workmail_domain.result.txt_name
  type    = "TXT"
  ttl     = var.dns_ttl
  records = [data.external.workmail_domain.result.txt_value]

  lifecycle {
    ignore_changes = [records]
  }
}

resource "aws_route53_record" "workmail_cname" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.external.workmail_domain.result.cname_name
  type    = "CNAME"
  ttl     = var.dns_ttl
  records = [data.external.workmail_domain.result.cname_value]

  lifecycle {
    ignore_changes = [records]
  }
}

# MX Record - REQUIRED for domain verification and user registration
resource "aws_route53_record" "workmail_mx" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.external.workmail_domain.result.mx_name
  type    = "MX"
  ttl     = var.dns_ttl
  records = [data.external.workmail_domain.result.mx_value]

  lifecycle {
    ignore_changes = [records]
  }
}

# =============================================================================
# 5. WorkMail User Creation & Registration (Optional)
# =============================================================================
resource "null_resource" "workmail_user" {
  count = var.create_user ? 1 : 0

  triggers = {
    org_id   = local.effective_org_id
    username = var.workmail_user
    domain   = var.domain_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${path.module}/scripts/workmail_user.sh \
        '${local.effective_org_id}' \
        '${var.workmail_user}' \
        '${var.workmail_password != null ? var.workmail_password : "null"}' \
        '${var.workmail_region}' \
        '${var.aws_profile != null ? var.aws_profile : ""}' \
        '${var.domain_name}'
    EOT
  }

  # Wait for ALL DNS records to be created before attempting user registration
  depends_on = [
    data.external.workmail_org,
    aws_route53_record.workmail_txt,
    aws_route53_record.workmail_cname,
    aws_route53_record.workmail_mx
  ]
}
