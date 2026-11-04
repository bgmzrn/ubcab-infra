# Shared / platform SGs (one file per SG under ./security-groups).
module "security_groups" {
  source = "./security-groups"

  vpc_id                    = aws_default_vpc.main.id
  env                       = var.env
  managed_repo              = var.managed_repo
  private_subnets           = var.private_subnets
  web_server_sg             = var.web_server_sg
  web_server_ssh_cidrs      = var.web_server_ssh_cidrs
  nat_sg                    = var.nat_sg
  nat_ssh_cidrs             = var.nat_ssh_cidrs
  mysql_sg                  = var.mysql_sg
  private_ssh_sg            = var.private_ssh_sg
  private_ssh_ingress_cidrs = var.private_ssh_ingress_cidrs
  default_sg                = var.default_sg
  redis_sg                  = var.redis_sg
  redis_ingress_cidrs       = var.redis_ingress_cidrs
  rabbitmq_sg               = var.rabbitmq_sg
  rabbitmq_mgmt_cidrs       = var.rabbitmq_mgmt_cidrs
  rabbitmq_prometheus_cidrs = var.rabbitmq_prometheus_cidrs
}
