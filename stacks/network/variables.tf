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
  type = string
}

# VPC
variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type        = string
  description = "Primary VPC CIDR"
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
