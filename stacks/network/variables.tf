variable "name" {
  type        = string
  description = "Name of the stack."
  default     = "network"
}

variable "env" {
  type        = string
  description = "Account-scope for backend path: nonprod | prod."

  validation {
    condition     = contains(["nonprod", "prod"], var.env)
    error_message = "env must be nonprod or prod (network is account-scoped)."
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

# VPC
variable "vpc_name" {
  type = string
}

variable "vpc_secondary_cidrs" {
  type        = list(string)
  description = "Extra associated IPv4 CIDRs (not the primary). Empty = none."
  default     = []
}

variable "enable_dns_support" {
  type = bool
}

variable "enable_dns_hostnames" {
  type = bool
}

# Subnets
variable "public_subnets" {
  type = map(object({
    cidr_block = string
    az         = string
    name       = string
  }))
  description = "Public subnets keyed by AZ suffix (e.g. a, b, c)."
  default     = {}
}

variable "private_subnets" {
  type = map(object({
    cidr_block = string
    az         = string
    name       = string
  }))
  description = "Private subnets keyed by AZ suffix (e.g. a, b, c)."
  default     = {}
}

variable "managed_repo" {
  type        = string
  description = "Managed repo name"
  default     = "ubcabv4-infra"
}
