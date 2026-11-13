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

variable "github_actions_role_name" {
  type        = string
  description = "IAM role for apply (OIDC sub: main + prod-v* tags)."
  default     = "gha-tf-shared"
}

variable "github_actions_plan_role_name" {
  type        = string
  description = "IAM role for PR plan (OIDC sub: pull_request)."
  default     = "gha-tf-shared-plan"
}

variable "github_repository" {
  type        = string
  description = "GitHub OIDC repo path: OWNER@owner_id/NAME@repo_id."

  validation {
    condition     = can(regex("^[^/@]+@[0-9]+/[^/@]+@[0-9]+$", var.github_repository))
    error_message = "github_repository must be OWNER@owner_id/NAME@repo_id."
  }
}
