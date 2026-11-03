resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name        = each.value.name
    ManagedRepo = var.managed_repo
    Environment = var.env
    Tier        = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = {
    Name        = each.value.name
    ManagedRepo = var.managed_repo
    Environment = var.env
    Tier        = "private"
  }
}
