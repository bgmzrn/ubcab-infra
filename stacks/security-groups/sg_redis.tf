resource "aws_security_group" "redis" {
  name        = var.redis_sg.name
  description = var.redis_sg.description
  vpc_id      = var.vpc_id

  tags = {
    Name        = var.redis_sg.name
    ManagedRepo = module.constants.managed_repo
    Environment = var.env
  }

  # Inline rules ignored — managed via aws_vpc_security_group_*_rule below.
  # Live SG has no egress rules; do not add an egress_* resource.
  lifecycle {
    ignore_changes = [ingress, egress]
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis" {
  for_each = var.redis_ingress_cidrs

  security_group_id = aws_security_group.redis.id
  ip_protocol       = "tcp"
  from_port         = 6379
  to_port           = 6379
  cidr_ipv4         = each.value.cidr
  description       = each.value.description != "" ? each.value.description : null
}
