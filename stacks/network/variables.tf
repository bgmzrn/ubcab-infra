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

# VPC
variable "vpc_name" {
  type = string
}

variable "vpc_secondary_cidr" {
  type        = string
  description = "Extra associated IPv4 CIDR (not the primary). Empty = none."
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

variable "private_subnet_extra_tags" {
  type        = map(string)
  description = "Extra tags applied to all private subnets (e.g. k8s discovery tags in nonprod)."
  default     = {}
}


# Import variables (delete after import is done)
variable "import_aws_default_vpc_main" {
  type = string
}
variable "import_aws_vpc_ipv4_cidr_block_association_secondary" {
  type = string
}

variable "import_public_subnets" {
  type = object({
    a = string
    b = string
    c = string
  })
}
variable "import_private_subnets" {
  type = object({
    a = string
    b = string
    c = string
  })
}
