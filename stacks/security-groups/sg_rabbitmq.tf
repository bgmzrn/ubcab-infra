resource "aws_security_group" "rabbitmq" {
  name        = var.rabbitmq_sg.name
  description = var.rabbitmq_sg.description
  vpc_id      = var.vpc_id

  tags = {
    Name        = var.rabbitmq_sg.name
    ManagedRepo = var.managed_repo
    Environment = var.env
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq_amqp" {
  security_group_id = aws_security_group.rabbitmq.id
  ip_protocol       = "tcp"
  from_port         = 5672
  to_port           = 5672
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Amqp"
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq_epmd" {
  security_group_id = aws_security_group.rabbitmq.id
  ip_protocol       = "tcp"
  from_port         = 4369
  to_port           = 4369
  cidr_ipv4         = "0.0.0.0/0"
  description       = "EPMD (Erlang node discovery)"
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq_erlang" {
  security_group_id = aws_security_group.rabbitmq.id
  ip_protocol       = "tcp"
  from_port         = 25672
  to_port           = 25672
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Erlang inter-node communication"
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq_mgmt" {
  for_each = var.rabbitmq_mgmt_cidrs

  security_group_id = aws_security_group.rabbitmq.id
  ip_protocol       = "tcp"
  from_port         = 15672
  to_port           = 15672
  cidr_ipv4         = each.value.cidr
  description       = each.value.description
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq_prometheus" {
  for_each = var.rabbitmq_prometheus_cidrs

  security_group_id = aws_security_group.rabbitmq.id
  ip_protocol       = "tcp"
  from_port         = 15692
  to_port           = 15692
  cidr_ipv4         = each.value.cidr
  description       = each.value.description
}

# Live rule is tcp 0–0 (not all-protocol); keep exact match for import.
resource "aws_vpc_security_group_egress_rule" "rabbitmq_tcp" {
  security_group_id = aws_security_group.rabbitmq.id
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}
