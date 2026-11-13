name = "security-groups"
env  = "nonprod"

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

import_aws_security_group_web_server = "sg-035801f30d23d0c1f"
import_web_server_http               = "sgr-0da3d1045280eba7f"
import_web_server_https              = "sgr-0f99655ce3d237a19"
import_web_server_ssh = {
  mezorn = "sgr-0279743d5cf61b243"
  boldoo = "sgr-0ca58b060964a69f7"
}
import_web_server_all = "sgr-000f3619117e0a01c"

import_aws_security_group_nat = "sg-04ffc8b94faa407ca"
import_nat_private = {
  a = "sgr-0994cccf188772ca0"
  b = "sgr-007fc5a52a60a0785"
  c = "sgr-0619c1887e6f76fad"
}
import_nat_ssh = {
  office         = "sgr-09f75944ecacebdbb"
  office_mobinet = "sgr-09ff03010bc8836e3"
  office_alt     = "sgr-0715c4562362dcb50"
}
import_nat_all = "sgr-00b8e0eed8e531f59"

import_aws_security_group_mysql = "sg-0619243182b900919"
import_mysql_from_nat           = "sgr-064a8062542e198b7"
import_mysql_from_web_server    = "sgr-0da160c69dbfd1bf1"
import_mysql_all                = "sgr-0940677cfd2f13926"

import_aws_security_group_private_ssh = "sg-0d052b88ef17de5fd"
import_private_ssh_cidr = {
  host = "sgr-0d400de3117d944e8"
}
import_private_ssh_from_nat = "sgr-08df9c4da13e2a242"
import_private_ssh_https    = "sgr-0646ad22eb190bd45"
import_private_ssh_all      = "sgr-0f9cf5dca4741a562"

import_aws_default_security_group_default = "sg-037d60015e8ac3b5c"

import_aws_security_group_redis = "sg-0aed318e084900283"
import_redis = {
  primary   = "sgr-07e17df73feb7ceb3"
  secondary = "sgr-058ba37f40a0c9bf3"
}

import_aws_security_group_rabbitmq = "sg-01eee1b8a0ac727e7"
import_rabbitmq_amqp               = "sgr-0d4af01ba1a607d8b"
import_rabbitmq_epmd               = "sgr-030c96fa2ad057fa6"
import_rabbitmq_erlang             = "sgr-018c0ff7855660ea0"
import_rabbitmq_mgmt = {
  unitel  = "sgr-00c19cd8bd0d576d0"
  mobinet = "sgr-04bdb0cd0f8457c44"
}
import_rabbitmq_prometheus = {
  mobinet = "sgr-0b46a220f5de06ce0"
}
import_rabbitmq_tcp = "sgr-08f83788e8d07f515"

import_aws_security_group_postgresql = "sg-05301b7d429be819f"
import_postgresql_private = {
  a = "sgr-00ea4c022ad88d95b"
  b = "sgr-05c46f6ea044b00d8"
  c = "sgr-06c41031b736d05f2"
}
import_postgresql_extra = {
  nat_tunnel = "sgr-0324459a76ec2c2c5"
  public_z   = "sgr-0cca24e6ad08ce532"
}
import_postgresql_all = "sgr-0263f2856c407ff48"

import_aws_security_group_bastion = "sg-09d66e431b9e07682"
import_bastion_http               = "sgr-02a092558c01d1ec8"
import_bastion_https              = "sgr-0b07efd2c0750ce79"
import_bastion_ssh = {
  mobinet      = "sgr-0afa4c620887e0cf6"
  nat_instance = "sgr-012976cfa4db27a77"
}
import_bastion_ssh_from_nat     = "sgr-0e8822589d79e7e69"
import_bastion_https_to_default = "sgr-0634bf559ceb68493"
import_bastion_all              = "sgr-0c3d3720bb5bb5be0"

