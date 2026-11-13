resource "aws_security_group" "bastion" {
  name        = var.bastion_sg.name
  description = var.bastion_sg.description
  vpc_id      = var.vpc_id

  tags = {
    Name        = var.bastion_sg.name
    ManagedRepo = module.constants.managed_repo
    Environment = var.env
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_http" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_https" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  for_each = var.bastion_ssh_cidrs

  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value.cidr
  description       = each.value.description != "" ? each.value.description : null
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_from_nat" {
  security_group_id            = aws_security_group.bastion.id
  referenced_security_group_id = aws_security_group.nat.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_https_to_default" {
  security_group_id            = aws_security_group.bastion.id
  referenced_security_group_id = aws_default_security_group.default.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
