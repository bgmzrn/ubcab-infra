variable "name" {
  type        = string
  description = "Name of the stack."
  default     = "iam"
}

variable "env" {
  type        = string
  description = "Account-scope for backend path: nonprod | prod."

  validation {
    condition     = contains(["nonprod", "prod"], var.env)
    error_message = "env must be nonprod or prod (iam is account-scoped)."
  }
}

variable "aws_profile" {
  type        = string
  description = "AWS shared-credentials profile for local use. Leave empty in CI (env credentials)."
  default     = ""
}

variable "github_actions_role_name" {
  type        = string
  description = "IAM role name assumed by GitHub Actions via OIDC."
  default     = "gha-tf-shared"
}

variable "github_repository" {
  type        = string
  description = "GitHub repo (owner/name) allowed in the OIDC sub claim."
  default     = "mezorn-com/ubcabv4-infra"
}
