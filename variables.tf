# =============================================================================
# TERRAFORM AWS EMAIL INFRASTRUCTURE - VARIABLES
# =============================================================================

variable "domain_name" {
  description = "The domain name to use (e.g., example.com). Must have Route 53 hosted zone."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format (e.g., example.com)."
  }
}

variable "workmail_org_id" {
  description = "Optional: Existing WorkMail organization ID. If not provided, one will be created/found."
  type        = string
  default     = null
}

variable "workmail_user" {
  description = "The username to create in WorkMail (e.g., 'info', 'admin')."
  type        = string
  default     = "info"

  validation {
    condition     = can(regex("^[a-z0-9._-]+$", var.workmail_user))
    error_message = "WorkMail username must contain only lowercase letters, numbers, dots, underscores, or hyphens."
  }
}

variable "workmail_password" {
  description = "Initial password for WorkMail user. Only required for NEW user creation. Must meet AWS password requirements."
  type        = string
  default     = null
  sensitive   = true
}

variable "workmail_region" {
  description = "AWS region for WorkMail. Only us-east-1, us-west-2, and eu-west-1 are supported."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-west-2", "eu-west-1"], var.workmail_region)
    error_message = "WorkMail is only available in us-east-1, us-west-2, and eu-west-1."
  }
}

variable "aws_profile" {
  description = "AWS CLI profile for WorkMail and Route 53 operations. Set to null to use default credentials."
  type        = string
  default     = null
}

variable "create_user" {
  description = "Whether to create a WorkMail user. Set to false if you only want to set up the domain."
  type        = bool
  default     = true
}

variable "dns_ttl" {
  description = "TTL for DNS records in seconds."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Tags to apply to resources that support tagging."
  type        = map(string)
  default     = {}
}
