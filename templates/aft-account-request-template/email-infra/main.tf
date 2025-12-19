# =============================================================================
# AFT ACCOUNT REQUEST - EMAIL INFRASTRUCTURE
# =============================================================================
#
# This folder uses the terraform-aws-email-infra module from GitHub to set up
# WorkMail infrastructure before requesting AWS accounts via AFT.
#
# =============================================================================

terraform {
  required_version = ">= 1.0"

  # Backend configuration - customize per organization
  # backend "s3" {
  #   bucket  = "ORG_NAME-email-infra-state"
  #   key     = "email-infra/terraform.tfstate"
  #   region  = "us-east-1"
  #   encrypt = true
  # }
}

provider "aws" {
  region  = var.workmail_region
  profile = var.aws_profile
}

# -----------------------------------------------------------------------------
# Configuration Variables
# -----------------------------------------------------------------------------
variable "aws_profile" {
  description = "AWS CLI profile for WorkMail and Route 53 operations"
  type        = string
  default     = "default"
}

variable "workmail_region" {
  description = "AWS region for WorkMail (us-east-1, us-west-2, or eu-west-1)"
  type        = string
  default     = "us-east-1"
}

variable "workmail_passwords" {
  description = <<-EOT
    Map of domain names to WorkMail user passwords.
    Only required when creating NEW WorkMail users.
    
    Example in terraform.tfvars:
    workmail_passwords = {
      "example.com"    = "SecurePassword123!"
      "mydomain.com"   = "AnotherPassword456!"
    }
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}

# -----------------------------------------------------------------------------
# EXAMPLE: Set up email for a new domain
# -----------------------------------------------------------------------------
# Uncomment and customize for each domain:
#
# module "example_domain" {
#   source = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"
#
#   domain_name       = "example.com"
#   workmail_user     = "info"
#   workmail_password = var.workmail_passwords["example.com"]
#   aws_profile       = var.aws_profile
#   workmail_region   = var.workmail_region
# }
#
# output "example_domain_email" {
#   value = module.example_domain.email_address
# }
#
# output "example_domain_aft_snippet" {
#   value     = module.example_domain.aft_account_request_snippet
#   sensitive = false
# }

# -----------------------------------------------------------------------------
# ADD YOUR DOMAINS BELOW
# -----------------------------------------------------------------------------
# Copy the example block above and customize for each domain you need.
# After running `terraform apply`, copy the aft_account_request_snippet
# output to ../terraform/main.tf to create the AWS account.
