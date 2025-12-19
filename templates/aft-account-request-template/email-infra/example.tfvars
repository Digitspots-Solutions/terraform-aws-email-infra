# Example terraform.tfvars - copy to terraform.tfvars and fill in values
# DO NOT COMMIT terraform.tfvars TO GIT

aws_profile     = "your-org-domain-profile"
workmail_region = "us-east-1"

workmail_passwords = {
  "example.com"  = "SecurePassword123!"
  "another.com"  = "AnotherPassword456!"
}
