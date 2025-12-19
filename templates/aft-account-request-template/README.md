# AFT Account Request Repository Template

This is a template for organization-specific AFT account request repositories.

## Repository Structure

```
aft-account-request-{orgname}/
├── email-infra/              # WorkMail setup (uses GitHub module)
│   ├── main.tf               # Module calls for each domain
│   ├── example.tfvars        # Example variables
│   └── terraform.tfvars      # Your passwords (not committed)
├── terraform/                # AFT account requests
│   ├── main.tf               # Account request modules
│   ├── versions.tf
│   └── modules/
│       └── aft-account-request/
└── README.md
```

## Workflow

### 1. Set Up Email Infrastructure

```bash
cd email-infra
cp example.tfvars terraform.tfvars
# Edit terraform.tfvars with your passwords
terraform init
terraform apply
```

### 2. Add Domain Modules

Edit `email-infra/main.tf`:

```hcl
module "mydomain" {
  source = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"

  domain_name       = "mydomain.com"
  workmail_user     = "info"
  workmail_password = var.workmail_passwords["mydomain.com"]
  aws_profile       = var.aws_profile
}

output "mydomain_aft_snippet" {
  value = module.mydomain.aft_account_request_snippet
}
```

### 3. Create AFT Account Request

After `terraform apply`, copy the output snippet to `terraform/main.tf`:

```hcl
module "mydomain" {
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail              = "info@mydomain.com"
    AccountName               = "mydomain"
    ManagedOrganizationalUnit = "ou-xxxx-xxxxxxxx"
    SSOUserEmail              = "info@mydomain.com"
    SSOUserFirstName          = "John"
    SSOUserLastName           = "Doe"
  }

  account_tags = {
    "Opportunity" = "true"
  }

  account_customizations_name = "sandbox"
}
```

### 4. Trigger AFT Pipeline

```bash
git add terraform/main.tf
git commit -m "Add account request for mydomain.com"
git push
```

The AFT pipeline will automatically provision the AWS account.

## Module Version Pinning

Always pin the email-infra module to a specific version:

```hcl
source = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"
```

Check the [releases page](https://github.com/Digitspots-Solutions/terraform-aws-email-infra/releases) for available versions.
