resource "aws_security_group" "private_ssh" {
  name        = var.private_ssh_sg.name
  description = var.private_ssh_sg.description
  vpc_id      = var.vpc_id

  tags = {
    Name        = var.private_ssh_sg.name
    ManagedRepo = module.constants.managed_repo
    Environment = var.env
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_ssh_cidr" {
  for_each = var.private_ssh_ingress_cidrs

  security_group_id = aws_security_group.private_ssh.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value.cidr
  description       = each.value.description != "" ? each.value.description : null
}

resource "aws_vpc_security_group_ingress_rule" "private_ssh_from_nat" {
  security_group_id            = aws_security_group.private_ssh.id
  referenced_security_group_id = aws_security_group.nat.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "private_ssh_https" {
  security_group_id            = aws_security_group.private_ssh.id
  referenced_security_group_id = aws_default_security_group.default.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "private_ssh_all" {
  security_group_id = aws_security_group.private_ssh.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
