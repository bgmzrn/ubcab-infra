name = "security-groups"
env  = "nonprod"

aws_profile = ""

vpc_id = "vpc-0e4c0c5f87416d4f6"

private_subnets = {
  a = {
    cidr_block = "172.31.128.0/18"
    az         = "ap-southeast-1a"
    name       = "privateA"
  }
  b = {
    cidr_block = "172.31.192.0/19"
    az         = "ap-southeast-1b"
    name       = "privateB"
  }
  c = {
    cidr_block = "172.31.224.0/19"
    az         = "ap-southeast-1c"
    name       = "privateC"
  }
}

web_server_sg = {
  name        = "web-server"
  description = "allows 80, 443, 22"
}

web_server_ssh_cidrs = {
  mezorn = {
    cidr        = "64.119.31.184/32"
    description = "SSH for Mezorn office"
  }
  boldoo = {
    cidr        = "66.181.179.29/32"
    description = "boldoo home"
  }
}

nat_sg = {
  name        = "NATSecurityGroup"
  description = "Security group for nat instance"
}

nat_ssh_cidrs = {
  office = {
    cidr        = "64.119.31.184/32"
    description = "office ip"
  }
  office_mobinet = {
    cidr        = "202.21.124.26/32"
    description = "office ip (mobinet)"
  }
  office_alt = {
    cidr        = "66.181.166.112/32"
    description = "office ip"
  }
}

mysql_sg = {
  name        = "MysqlSG"
  description = "Allow access on 3306"
}

private_ssh_sg = {
  name        = "private-ssh"
  description = "Private ssh"
}

private_ssh_ingress_cidrs = {
  host = {
    cidr        = "172.31.23.174/32"
    description = ""
  }
}

default_sg = {
  name = "Default SG"
}

redis_sg = {
  name        = "redisSG"
  description = "allow redis access for vpc"
}

redis_ingress_cidrs = {
  primary = {
    cidr        = "172.31.0.0/16"
    description = "allow redis access for vpc"
  }
  secondary = {
    cidr        = "172.30.0.0/16"
    description = ""
  }
}

rabbitmq_sg = {
  name        = "rabbitmq"
  description = "RabbitMQ security group"
}

rabbitmq_mgmt_cidrs = {
  unitel = {
    cidr        = "66.181.166.112/32"
    description = "Management UI - Mezorn - Central Park (Unitel)"
  }
  mobinet = {
    cidr        = "202.21.124.26/32"
    description = "Management UI - Mezorn - Central Park (Mobinet)"
  }
}

rabbitmq_prometheus_cidrs = {
  mobinet = {
    cidr        = "202.21.124.26/32"
    description = "Prometheus UI"
  }
}

postgresql_sg = {
  name        = "postgresql-sg"
  description = "Created by RDS management console"
}

postgresql_ingress_cidrs = {
  nat_tunnel = {
    cidr        = "172.31.23.174/32"
    description = "nat tunnel"
  }
  public_z = {
    cidr        = "0.0.0.0/0"
    description = "public z"
  }
}

bastion_sg = {
  name        = "bastion-sg"
  description = "Bastion host SG"
}

bastion_ssh_cidrs = {
  mobinet = {
    cidr        = "202.21.124.26/32"
    description = "Mezorn office - Mobinet"
  }
  nat_instance = {
    cidr        = "172.31.23.174/32"
    description = "NAT Instance"
  }
}
