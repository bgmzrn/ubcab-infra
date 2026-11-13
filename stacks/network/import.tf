import {
  to = aws_default_vpc.main
  id = var.import_aws_default_vpc_main
}

# Secondary CIDR only — primary association stays on aws_vpc.main
import {
  to = aws_vpc_ipv4_cidr_block_association.secondary
  id = var.import_aws_vpc_ipv4_cidr_block_association_secondary
}

import {
  to = aws_subnet.public["a"]
  id = var.import_public_subnets["a"]
}
import {
  to = aws_subnet.public["b"]
  id = var.import_public_subnets["b"]
}
import {
  to = aws_subnet.public["c"]
  id = var.import_public_subnets["c"]
}

import {
  to = aws_subnet.private["a"]
  id = var.import_private_subnets["a"]
}
import {
  to = aws_subnet.private["b"]
  id = var.import_private_subnets["b"]
}
import {
  to = aws_subnet.private["c"]
  id = var.import_private_subnets["c"]
}
