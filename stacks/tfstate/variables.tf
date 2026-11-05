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

variable "aws_profile" {
  type        = string
  description = "AWS shared-credentials profile for local use. Leave empty in CI (env credentials)."
  default     = ""
}

variable "bucket_name" {
  type        = string
  description = "Existing Terraform state bucket name (from bootstrap-bucket.sh)."
}
