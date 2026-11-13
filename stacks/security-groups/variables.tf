variable "name" {
  type        = string
  description = "Name of the stack."
  default     = "security-groups"
}

variable "env" {
  type        = string
  description = "Account-scope for backend path: nonprod | prod."

  validation {
    condition     = contains(["nonprod", "prod"], var.env)
    error_message = "env must be nonprod or prod (security-groups is account-scoped)."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID from the network stack (SGs are attached to this VPC)."
}

variable "private_subnets" {
  type = map(object({
    cidr_block = string
    az         = string
    name       = string
  }))
  description = "Private subnet CIDRs keyed by AZ suffix (used by NAT / PostgreSQL ingress). Keep in sync with the network stack."
  default     = {}
}

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

variable "postgresql_sg" {
  type = object({
    name        = string
    description = string
  })
  description = "PostgreSQL / RDS security group (shell; rules are separate resources)."
}

variable "postgresql_ingress_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
  description = "Extra CIDR allowlist for PostgreSQL (5432), beyond private subnets."
  default     = {}
}

variable "bastion_sg" {
  type = object({
    name        = string
    description = string
  })
  description = "Bastion host security group (shell; rules are separate resources)."
}

variable "bastion_ssh_cidrs" {
  type = map(object({
    cidr        = string
    description = string
  }))
  description = "SSH allowlist CIDRs for bastion SG."
  default     = {}
}

# Import variables (delete after import is done)
variable "import_aws_security_group_web_server" {
  type = string
}
variable "import_web_server_http" {
  type = string
}
variable "import_web_server_https" {
  type = string
}
variable "import_web_server_ssh" {
  type = object({
    mezorn = string
    boldoo = string
  })
}
variable "import_web_server_all" {
  type = string
}

variable "import_aws_security_group_nat" {
  type = string
}
variable "import_nat_private" {
  type = object({
    a = string
    b = string
    c = string
  })
}
variable "import_nat_ssh" {
  type = object({
    office         = string
    office_mobinet = string
    office_alt     = string
  })
}
variable "import_nat_all" {
  type = string
}

variable "import_aws_security_group_mysql" {
  type = string
}
variable "import_mysql_from_nat" {
  type = string
}
variable "import_mysql_from_web_server" {
  type = string
}
variable "import_mysql_all" {
  type = string
}

variable "import_aws_security_group_private_ssh" {
  type = string
}
variable "import_private_ssh_cidr" {
  type = object({
    host = string
  })
}
variable "import_private_ssh_from_nat" {
  type = string
}
variable "import_private_ssh_https" {
  type = string
}
variable "import_private_ssh_all" {
  type = string
}

variable "import_aws_default_security_group_default" {
  type = string
}

variable "import_aws_security_group_redis" {
  type = string
}
variable "import_redis" {
  type = object({
    primary   = string
    secondary = string
  })
}

variable "import_aws_security_group_rabbitmq" {
  type = string
}
variable "import_rabbitmq_amqp" {
  type = string
}
variable "import_rabbitmq_epmd" {
  type = string
}
variable "import_rabbitmq_erlang" {
  type = string
}
variable "import_rabbitmq_mgmt" {
  type = object({
    unitel  = string
    mobinet = string
  })
}
variable "import_rabbitmq_prometheus" {
  type = object({
    mobinet = string
  })
}
variable "import_rabbitmq_tcp" {
  type = string
}

variable "import_aws_security_group_postgresql" {
  type = string
}
variable "import_postgresql_private" {
  type = object({
    a = string
    b = string
    c = string
  })
}
variable "import_postgresql_extra" {
  type = object({
    nat_tunnel = string
    public_z   = string
  })
}
variable "import_postgresql_all" {
  type = string
}

variable "import_aws_security_group_bastion" {
  type = string
}
variable "import_bastion_http" {
  type = string
}
variable "import_bastion_https" {
  type = string
}
variable "import_bastion_ssh" {
  type = object({
    mobinet      = string
    nat_instance = string
  })
}
variable "import_bastion_ssh_from_nat" {
  type = string
}
variable "import_bastion_https_to_default" {
  type = string
}
variable "import_bastion_all" {
  type = string
}

