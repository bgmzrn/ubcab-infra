output "vpc_id" {
  description = "Default VPC ID (consumed by security-groups and other stacks)."
  value       = aws_default_vpc.main.id
}

output "private_subnets" {
  description = "Private subnet definitions (CIDRs keyed by AZ suffix)."
  value       = var.private_subnets
}
