resource "aws_security_group" "mysql" {
  name        = var.mysql_sg.name
  description = var.mysql_sg.description
  vpc_id      = var.vpc_id

  tags = {
    Name        = var.mysql_sg.name
    ManagedRepo = module.constants.managed_repo
    Environment = var.env
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_vpc_security_group_ingress_rule" "mysql_from_nat" {
  security_group_id            = aws_security_group.mysql.id
  referenced_security_group_id = aws_security_group.nat.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  description                  = "allow mysql connection via tunnel"
}

resource "aws_vpc_security_group_ingress_rule" "mysql_from_web_server" {
  security_group_id            = aws_security_group.mysql.id
  referenced_security_group_id = aws_security_group.web_server.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  description                  = "allow mysql conn from ec2"
}

resource "aws_vpc_security_group_egress_rule" "mysql_all" {
  security_group_id = aws_security_group.mysql.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
