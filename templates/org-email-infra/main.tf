# =============================================================================
# EMAIL INFRASTRUCTURE SETUP
# =============================================================================
# 
# This file sets up WorkMail email infrastructure for this organization.
# It uses the shared terraform-aws-email-infra module from GitHub.
#
# WORKFLOW:
#   1. Add a new module block below for your domain
#   2. Add password to terraform.tfvars (not committed to git)
#   3. Run: terraform init && terraform apply
#   4. Copy the aft_account_request_snippet output to ../terraform/main.tf
#   5. Commit and push to trigger AFT pipeline
#
# =============================================================================

terraform {
  required_version = ">= 1.0"
  
  # Optional: Configure backend for state storage
  # backend "s3" {
  #   bucket  = "org-name-terraform-state"
  #   key     = "email-infra/terraform.tfstate"
  #   region  = "us-east-1"
  #   encrypt = true
  # }
}

provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "aws_profile" {
  description = "AWS CLI profile for WorkMail and Route 53 operations"
  type        = string
  default     = "default"  # Change to your org's profile
}

variable "workmail_passwords" {
  description = "Map of domain names to WorkMail user passwords"
  type        = map(string)
  sensitive   = true
  default     = {}
}

# -----------------------------------------------------------------------------
# EXAMPLE DOMAIN - Copy and modify this block for each new domain
# -----------------------------------------------------------------------------
# module "example_domain" {
#   source = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"
#
#   domain_name       = "example.com"
#   workmail_user     = "info"
#   workmail_password = var.workmail_passwords["example.com"]
#   aws_profile       = var.aws_profile
# }
#
# output "example_domain_email" {
#   value = module.example_domain.email_address
# }
#
# output "example_domain_aft_snippet" {
#   value = module.example_domain.aft_account_request_snippet
# }

# -----------------------------------------------------------------------------
# ADD YOUR DOMAINS BELOW
# -----------------------------------------------------------------------------

