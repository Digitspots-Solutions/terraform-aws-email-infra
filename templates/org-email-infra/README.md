# Organization Email Infrastructure

This folder contains Terraform configuration for setting up WorkMail email infrastructure.

## Quick Start

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Configure your domains**
   
   Edit `main.tf` and add a module block for each domain:
   ```hcl
   module "mydomain" {
     source = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"

     domain_name       = "mydomain.com"
     workmail_user     = "info"
     workmail_password = var.workmail_passwords["mydomain.com"]
     aws_profile       = var.aws_profile
   }

   output "mydomain_email" {
     value = module.mydomain.email_address
   }

   output "mydomain_aft_snippet" {
     value = module.mydomain.aft_account_request_snippet
   }
   ```

3. **Create terraform.tfvars** (do not commit to git)
   ```hcl
   aws_profile = "your-aws-profile"
   
   workmail_passwords = {
     "mydomain.com" = "SecurePassword123!"
   }
   ```

4. **Apply the configuration**
   ```bash
   terraform apply
   ```

5. **Copy the AFT snippet**
   
   The output will include an `aft_account_request_snippet` - copy this to `../terraform/main.tf`

6. **Commit and push** to trigger the AFT pipeline

## Adding More Domains

Simply add another module block and output. The WorkMail organization will be reused automatically.

## Troubleshooting

- **Domain not found**: Ensure the domain has a Route53 hosted zone
- **Password requirements**: AWS requires 8+ characters with mixed case, numbers, and symbols
- **User already exists**: The script handles existing users gracefully
