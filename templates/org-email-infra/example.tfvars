# =============================================================================
# EMAIL INFRASTRUCTURE - EXAMPLE TFVARS
# =============================================================================
# 
# Copy this file to terraform.tfvars and fill in your values.
# DO NOT commit terraform.tfvars to git (it contains passwords)
#
# =============================================================================

# AWS CLI profile to use
aws_profile = "your-org-profile"

# WorkMail user passwords - one for each domain
workmail_passwords = {
  "example.com"   = "SecurePassword123!"
  "mydomain.com"  = "AnotherPassword456!"
}
