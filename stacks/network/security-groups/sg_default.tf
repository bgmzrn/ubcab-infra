# VPC default SG — adopt only; inline rules match AWS defaults (see provider docs).
resource "aws_default_security_group" "default" {
  vpc_id = var.vpc_id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  tags = {
    Name        = var.default_sg.name
    ManagedRepo = var.managed_repo
    Environment = var.env
  }
}
