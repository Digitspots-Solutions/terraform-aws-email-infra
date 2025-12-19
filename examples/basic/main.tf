# =============================================================================
# EXAMPLE: Using the terraform-aws-email-infra module
# =============================================================================
# 
# This file shows how to use the module from GitHub.
# Copy this to your project and customize as needed.
#
# =============================================================================

terraform {
  required_version = ">= 1.0"
}

# Configure AWS provider
provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile  # Optional: remove if using default credentials
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "workmail_passwords" {
  description = "Map of domain names to WorkMail user passwords"
  type        = map(string)
  sensitive   = true
  default     = {}
}

# -----------------------------------------------------------------------------
# Single Domain Example
# -----------------------------------------------------------------------------
module "example_domain" {
  # Use GitHub source with version pinning
  source = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"

  domain_name       = "example.com"
  workmail_user     = "info"
  workmail_password = var.workmail_passwords["example.com"]
  aws_profile       = var.aws_profile
}

output "example_email" {
  value = module.example_domain.email_address
}

output "example_aft_snippet" {
  value = module.example_domain.aft_account_request_snippet
}

# -----------------------------------------------------------------------------
# Multiple Domains Example
# -----------------------------------------------------------------------------
# Uncomment and customize for multiple domains:
#
# locals {
#   domains = {
#     "domain-a.com" = { user = "info" }
#     "domain-b.com" = { user = "admin" }
#     "domain-c.com" = { user = "support" }
#   }
# }
#
# module "email_infra" {
#   for_each = local.domains
#   source   = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"
#
#   domain_name       = each.key
#   workmail_user     = each.value.user
#   workmail_password = var.workmail_passwords[each.key]
#   aws_profile       = var.aws_profile
# }
#
# output "all_emails" {
#   value = { for k, v in module.email_infra : k => v.email_address }
# }
