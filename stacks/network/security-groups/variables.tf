variable "vpc_id" {
  type = string
}

variable "env" {
  type = string
}

variable "managed_repo" {
  type = string
}

variable "private_subnets" {
  type = map(object({
    cidr_block = string
    az         = string
    name       = string
  }))
}

variable "web_server_sg" {
  type = object({
    name        = string
    description = string
  })
}

variable "web_server_ssh_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
}

variable "nat_sg" {
  type = object({
    name        = string
    description = string
  })
}

variable "nat_ssh_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
}

variable "mysql_sg" {
  type = object({
    name        = string
    description = string
  })
}

variable "private_ssh_sg" {
  type = object({
    name        = string
    description = string
  })
}

variable "private_ssh_ingress_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
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
}

variable "redis_ingress_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
}

variable "rabbitmq_sg" {
  type = object({
    name        = string
    description = string
  })
}

variable "rabbitmq_mgmt_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
}

variable "rabbitmq_prometheus_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
}
