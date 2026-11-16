import {
  to = aws_security_group.web_server
  id = var.import_aws_security_group_web_server
}

import {
  to = aws_vpc_security_group_ingress_rule.web_server_http
  id = var.import_web_server_http
}
import {
  to = aws_vpc_security_group_ingress_rule.web_server_https
  id = var.import_web_server_https
}
import {
  to = aws_vpc_security_group_ingress_rule.web_server_ssh["mezorn"]
  id = var.import_web_server_ssh["mezorn"]
}
import {
  to = aws_vpc_security_group_ingress_rule.web_server_ssh["boldoo"]
  id = var.import_web_server_ssh["boldoo"]
}
import {
  to = aws_vpc_security_group_egress_rule.web_server_all
  id = var.import_web_server_all
}

import {
  to = aws_security_group.nat
  id = var.import_aws_security_group_nat
}

import {
  to = aws_vpc_security_group_ingress_rule.nat_private["a"]
  id = var.import_nat_private["a"]
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_private["b"]
  id = var.import_nat_private["b"]
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_private["c"]
  id = var.import_nat_private["c"]
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_ssh["office"]
  id = var.import_nat_ssh["office"]
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_ssh["office_mobinet"]
  id = var.import_nat_ssh["office_mobinet"]
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_ssh["office_alt"]
  id = var.import_nat_ssh["office_alt"]
}
import {
  to = aws_vpc_security_group_egress_rule.nat_all
  id = var.import_nat_all
}

import {
  to = aws_security_group.mysql
  id = var.import_aws_security_group_mysql
}

import {
  to = aws_vpc_security_group_ingress_rule.mysql_from_nat
  id = var.import_mysql_from_nat
}
import {
  to = aws_vpc_security_group_ingress_rule.mysql_from_web_server
  id = var.import_mysql_from_web_server
}
import {
  to = aws_vpc_security_group_egress_rule.mysql_all
  id = var.import_mysql_all
}

import {
  to = aws_security_group.private_ssh
  id = var.import_aws_security_group_private_ssh
}

import {
  to = aws_vpc_security_group_ingress_rule.private_ssh_cidr["host"]
  id = var.import_private_ssh_cidr["host"]
}
import {
  to = aws_vpc_security_group_ingress_rule.private_ssh_from_nat
  id = var.import_private_ssh_from_nat
}
import {
  to = aws_vpc_security_group_egress_rule.private_ssh_https
  id = var.import_private_ssh_https
}
import {
  to = aws_vpc_security_group_egress_rule.private_ssh_all
  id = var.import_private_ssh_all
}

import {
  to = aws_default_security_group.default
  id = var.import_aws_default_security_group_default
}

import {
  to = aws_security_group.redis
  id = var.import_aws_security_group_redis
}

import {
  to = aws_vpc_security_group_ingress_rule.redis["primary"]
  id = var.import_redis["primary"]
}
import {
  to = aws_vpc_security_group_ingress_rule.redis["secondary"]
  id = var.import_redis["secondary"]
}

import {
  to = aws_security_group.rabbitmq
  id = var.import_aws_security_group_rabbitmq
}

import {
  to = aws_vpc_security_group_ingress_rule.rabbitmq_amqp
  id = var.import_rabbitmq_amqp
}
import {
  to = aws_vpc_security_group_ingress_rule.rabbitmq_epmd
  id = var.import_rabbitmq_epmd
}
import {
  to = aws_vpc_security_group_ingress_rule.rabbitmq_erlang
  id = var.import_rabbitmq_erlang
}
import {
  to = aws_vpc_security_group_ingress_rule.rabbitmq_mgmt["unitel"]
  id = var.import_rabbitmq_mgmt["unitel"]
}
import {
  to = aws_vpc_security_group_ingress_rule.rabbitmq_mgmt["mobinet"]
  id = var.import_rabbitmq_mgmt["mobinet"]
}
import {
  to = aws_vpc_security_group_ingress_rule.rabbitmq_prometheus["mobinet"]
  id = var.import_rabbitmq_prometheus["mobinet"]
}
import {
  to = aws_vpc_security_group_egress_rule.rabbitmq_tcp
  id = var.import_rabbitmq_tcp
}

import {
  to = aws_security_group.postgresql
  id = var.import_aws_security_group_postgresql
}

import {
  to = aws_vpc_security_group_ingress_rule.postgresql_private["a"]
  id = var.import_postgresql_private["a"]
}
import {
  to = aws_vpc_security_group_ingress_rule.postgresql_private["b"]
  id = var.import_postgresql_private["b"]
}
import {
  to = aws_vpc_security_group_ingress_rule.postgresql_private["c"]
  id = var.import_postgresql_private["c"]
}
import {
  to = aws_vpc_security_group_ingress_rule.postgresql_extra["nat_tunnel"]
  id = var.import_postgresql_extra["nat_tunnel"]
}
import {
  to = aws_vpc_security_group_ingress_rule.postgresql_extra["public_z"]
  id = var.import_postgresql_extra["public_z"]
}
import {
  to = aws_vpc_security_group_egress_rule.postgresql_all
  id = var.import_postgresql_all
}

import {
  to = aws_security_group.bastion
  id = var.import_aws_security_group_bastion
}

import {
  to = aws_vpc_security_group_ingress_rule.bastion_http
  id = var.import_bastion_http
}
import {
  to = aws_vpc_security_group_ingress_rule.bastion_https
  id = var.import_bastion_https
}
import {
  to = aws_vpc_security_group_ingress_rule.bastion_ssh["mobinet"]
  id = var.import_bastion_ssh["mobinet"]
}
import {
  to = aws_vpc_security_group_ingress_rule.bastion_ssh["nat_instance"]
  id = var.import_bastion_ssh["nat_instance"]
}
import {
  to = aws_vpc_security_group_ingress_rule.bastion_ssh_from_nat
  id = var.import_bastion_ssh_from_nat
}
import {
  to = aws_vpc_security_group_egress_rule.bastion_https_to_default
  id = var.import_bastion_https_to_default
}
import {
  to = aws_vpc_security_group_egress_rule.bastion_all
  id = var.import_bastion_all
}
