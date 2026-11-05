variable "name" {
  type        = string
  description = "Name of the stack."
  default     = "tfstate"
}

variable "env" {
  type        = string
  description = "Account-scope for backend path: nonprod | prod."

  validation {
    condition     = contains(["nonprod", "prod"], var.env)
    error_message = "env must be nonprod or prod (tfstate is account-scoped)."
  }
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS shared-credentials profile for local use. Leave empty in CI (env credentials)."
  default     = ""
}

variable "bucket_name" {
  type        = string
  description = "Existing Terraform state bucket name (from bootstrap-bucket.sh)."
}

variable "managed_repo" {
  type        = string
  description = "Managed repo name"
  default     = "ubcabv4-infra"
}

variable "state_access" {
  type = map(object({
    prefixes       = list(string)
    principal_arns = list(string)
  }))
  description = <<-EOT
    Per-stack grants on this state bucket.
    Key = stack name (e.g. network).
    prefixes = object key patterns relative to the bucket (e.g. ["nonprod/network/*"]).
    principal_arns = IAM role or user ARNs allowed to use those prefixes (state + .tflock).
    Empty map = no extra IAM policies (bucket hardening only).
  EOT
  default     = {}

  validation {
    condition = alltrue([
      for stack, cfg in var.state_access : (
        length(cfg.prefixes) > 0 &&
        length(cfg.principal_arns) > 0 &&
        alltrue([
          for arn in cfg.principal_arns :
          can(regex("^arn:aws:iam::[0-9]+:(role|user)/.+$", arn))
        ])
      )
    ])
    error_message = "Each state_access entry needs non-empty prefixes and principal_arns; each ARN must be an iam role or user ARN."
  }
}
