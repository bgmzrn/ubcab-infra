resource "aws_security_group" "web_server" {
  name        = var.web_server_sg.name
  description = var.web_server_sg.description
  vpc_id      = var.vpc_id

  tags = {
    Name        = var.web_server_sg.name
    ManagedRepo = var.managed_repo
    Environment = var.env
  }

  # Inline rules ignored — managed via aws_vpc_security_group_*_rule below.
  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_server_http" {
  security_group_id = aws_security_group.web_server.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "web_server_https" {
  security_group_id = aws_security_group.web_server.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "web_server_ssh" {
  for_each = var.web_server_ssh_cidrs

  security_group_id = aws_security_group.web_server.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value.cidr
  description       = each.value.description
}

resource "aws_vpc_security_group_egress_rule" "web_server_all" {
  security_group_id = aws_security_group.web_server.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
