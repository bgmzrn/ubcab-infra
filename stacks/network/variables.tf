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

# Security groups
variable "web_server_sg" {
  type = object({
    name        = string
    description = string
  })
  description = "Shared web-server security group (shell; rules are separate resources)."
}

variable "web_server_ssh_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
  description = "SSH allowlist for web-server SG."
  default     = {}
}

variable "nat_sg" {
  type = object({
    name        = string
    description = string
  })
  description = "NAT instance security group (shell; rules are separate resources)."
}

variable "nat_ssh_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
  description = "SSH allowlist for NAT SG."
  default     = {}
}

variable "mysql_sg" {
  type = object({
    name        = string
    description = string
  })
  description = "MySQL security group (shell; rules are separate resources)."
}

variable "private_ssh_sg" {
  type = object({
    name        = string
    description = string
  })
  description = "Private SSH security group (shell; rules are separate resources)."
}

variable "private_ssh_ingress_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
  description = "SSH allowlist CIDRs for private-ssh SG."
  default     = {}
}

variable "default_sg" {
  type = object({
    name = string
  })
  description = "Name tag for the VPC default security group (group name is always \"default\")."
}

variable "redis_sg" {
  type = object({
    name        = string
    description = string
  })
  description = "Redis security group (shell; rules are separate resources)."
}

variable "redis_ingress_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
  description = "CIDR allowlist for Redis (6379)."
  default     = {}
}

variable "rabbitmq_sg" {
  type = object({
    name        = string
    description = string
  })
  description = "RabbitMQ security group (shell; rules are separate resources)."
}

variable "rabbitmq_mgmt_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
  description = "CIDR allowlist for RabbitMQ management UI (15672)."
  default     = {}
}

variable "rabbitmq_prometheus_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
  description = "CIDR allowlist for RabbitMQ Prometheus UI (15692)."
  default     = {}
}

variable "managed_repo" {
  type        = string
  description = "Managed repo name"
  default     = "ubcabv4-infra"
}
