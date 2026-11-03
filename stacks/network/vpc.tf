resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name        = var.vpc_name
    ManagedBy   = "terraform"
    ManagedRepo = "ubcabv4-infra"
    Environment = var.env
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  for_each = toset(var.vpc_secondary_cidrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
}
