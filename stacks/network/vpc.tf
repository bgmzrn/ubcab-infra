resource "aws_default_vpc" "main" {
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = var.vpc_name
    ManagedRepo = var.managed_repo
    Environment = var.env
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  for_each = toset(var.vpc_secondary_cidrs)

  vpc_id     = aws_default_vpc.main.id
  cidr_block = each.value
}
