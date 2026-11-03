import {
  to = aws_vpc.main
  id = "vpc-0e4c0c5f87416d4f6"
}

# Secondary CIDR only — primary association stays on aws_vpc.main
import {
  to = aws_vpc_ipv4_cidr_block_association.secondary["172.30.0.0/16"]
  id = "vpc-cidr-assoc-0743e2c4386d3d314"
}
