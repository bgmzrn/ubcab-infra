resource "aws_security_group" "nat" {
  name        = var.nat_sg.name
  description = var.nat_sg.description
  vpc_id      = var.vpc_id

  tags = {
    Name        = var.nat_sg.name
    ManagedRepo = var.managed_repo
    Environment = var.env
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_vpc_security_group_ingress_rule" "nat_private" {
  for_each = var.private_subnets

  security_group_id = aws_security_group.nat.id
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_ipv4         = each.value.cidr_block
  description       = "private ${each.key}"
}

resource "aws_vpc_security_group_ingress_rule" "nat_ssh" {
  for_each = var.nat_ssh_cidrs

  security_group_id = aws_security_group.nat.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value.cidr
  description       = each.value.description
}

resource "aws_vpc_security_group_egress_rule" "nat_all" {
  security_group_id = aws_security_group.nat.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
