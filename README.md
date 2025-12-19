# Terraform AWS Email Infrastructure Module

A reusable Terraform module for setting up AWS WorkMail with Route53 DNS verification. Designed to work standalone or as part of the Opportunity Account Portal ecosystem.

## Features

- ✅ Creates or finds existing WorkMail organization
- ✅ Registers domains with WorkMail
- ✅ Automatically creates DNS verification records in Route53
- ✅ Creates and enables WorkMail users with mailboxes
- ✅ Outputs ready-to-use AFT account request snippets
- ✅ Supports multiple domains per organization

## Usage

### Basic Usage (Single Domain)

```hcl
module "email_infra" {
  source  = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"

  domain_name       = "example.com"
  workmail_user     = "info"
  workmail_password = var.workmail_password  # From tfvars or secrets
}

output "email_address" {
  value = module.email_infra.email_address
}
```

### Multiple Domains

```hcl
module "domain_a" {
  source  = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"

  domain_name       = "domain-a.com"
  workmail_user     = "admin"
  workmail_password = var.passwords["domain-a.com"]
}

module "domain_b" {
  source  = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"

  domain_name       = "domain-b.com"
  workmail_user     = "info"
  workmail_password = var.passwords["domain-b.com"]
}
```

### With Existing WorkMail Organization

```hcl
module "email_infra" {
  source  = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"

  domain_name       = "example.com"
  workmail_org_id   = "m-0123456789abcdef0"  # Reuse existing org
  workmail_user     = "support"
  workmail_password = var.workmail_password
}
```

### Cross-Account Usage (Portal Pattern)

When using with the Opportunity Account Portal, the portal assumes a role in the target account:

```hcl
provider "aws" {
  alias  = "domain_account"
  region = "us-east-1"
  
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/PortalWorkMailAccess"
    external_id  = "OpportunityPortal-wedgewood"
  }
}

module "email_infra" {
  source  = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"
  
  providers = {
    aws = aws.domain_account
  }

  domain_name       = "example.com"
  workmail_user     = "info"
  workmail_password = var.workmail_password
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

### Prerequisites

1. **Route53 Hosted Zone**: The domain must have an existing Route53 hosted zone
2. **AWS Credentials**: Must have permissions for WorkMail, Route53, SES, and Directory Service
3. **Region**: WorkMail is only available in specific regions (us-east-1, us-west-2, eu-west-1)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| domain_name | Domain name (must have Route53 hosted zone) | `string` | n/a | yes |
| workmail_user | Username for WorkMail account | `string` | `"info"` | no |
| workmail_password | Password for WorkMail user (required for new users) | `string` | `null` | no |
| workmail_org_id | Existing WorkMail org ID (creates new if not provided) | `string` | `null` | no |
| workmail_region | AWS region for WorkMail | `string` | `"us-east-1"` | no |
| create_user | Whether to create a WorkMail user | `bool` | `true` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| email_address | Full email address (e.g., info@example.com) |
| domain_name | The domain name |
| workmail_org_id | WorkMail organization ID |
| workmail_user_id | WorkMail user ID |
| zone_id | Route53 hosted zone ID |
| dns_records | DNS records created for verification |
| aft_account_request_snippet | Ready-to-use AFT module block |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    terraform-aws-email-infra                │
├─────────────────────────────────────────────────────────────┤
│  1. Route53 Zone Lookup                                     │
│     └── data.aws_route53_zone                               │
│                                                             │
│  2. WorkMail Organization                                   │
│     └── scripts/workmail_org.sh (create or find)           │
│                                                             │
│  3. Domain Registration                                     │
│     └── scripts/workmail_domain.sh (register + get DNS)    │
│                                                             │
│  4. DNS Verification Records                                │
│     ├── aws_route53_record.txt (ownership verification)    │
│     ├── aws_route53_record.cname (autodiscover)            │
│     └── aws_route53_record.mx (mail routing)               │
│                                                             │
│  5. WorkMail User (optional)                                │
│     └── scripts/workmail_user.sh (create + enable mailbox) │
└─────────────────────────────────────────────────────────────┘
```

## Workflow Integration

### With AFT Account Factory

1. Run this module to set up email infrastructure
2. Use the `aft_account_request_snippet` output
3. Add the snippet to your AFT account request repo
4. Push to trigger account provisioning

### With Opportunity Account Portal

The portal calls this module's logic via Lambda functions, providing a self-service UI for non-technical users.

## Versioning

This module follows semantic versioning:

- `v1.x.x` - Stable releases
- `v1.0.0` - Initial release

Pin to a specific version in production:

```hcl
source = "git::https://github.com/Digitspots-Solutions/terraform-aws-email-infra.git?ref=v1.0.0"
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Related Projects

- [Opportunity Account Portal](https://github.com/Digitspots-Solutions/opportunity-account-portal) - Self-service UI
- [AFT Account Request Template](https://github.com/Digitspots-Solutions/learn-terraform-aft-account-request) - AFT integration
- [terraform-aws-portal-roles](https://github.com/Digitspots-Solutions/terraform-aws-portal-roles) - Cross-account IAM roles
