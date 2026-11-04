resource "aws_security_group" "postgresql" {
  name        = var.postgresql_sg.name
  description = var.postgresql_sg.description
  vpc_id      = var.vpc_id

  tags = {
    Name        = var.postgresql_sg.name
    ManagedRepo = var.managed_repo
    Environment = var.env
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgresql_private" {
  for_each = var.private_subnets

  security_group_id = aws_security_group.postgresql.id
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  cidr_ipv4         = each.value.cidr_block
  description       = "private ${each.key}"
}

resource "aws_vpc_security_group_ingress_rule" "postgresql_extra" {
  for_each = var.postgresql_ingress_cidrs

  security_group_id = aws_security_group.postgresql.id
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  cidr_ipv4         = each.value.cidr
  description       = each.value.description != "" ? each.value.description : null
}

resource "aws_vpc_security_group_egress_rule" "postgresql_all" {
  security_group_id = aws_security_group.postgresql.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
