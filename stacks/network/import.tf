import {
  to = aws_default_vpc.main
  id = "vpc-0e4c0c5f87416d4f6"
}

# Secondary CIDR only — primary association stays on aws_vpc.main
import {
  to = aws_vpc_ipv4_cidr_block_association.secondary["172.30.0.0/16"]
  id = "vpc-cidr-assoc-0743e2c4386d3d314"
}

import {
  to = aws_subnet.public["a"]
  id = "subnet-02ff1de080131916a"
}
import {
  to = aws_subnet.public["b"]
  id = "subnet-0662fa61fbc36cfbb"
}
import {
  to = aws_subnet.public["c"]
  id = "subnet-067873761256b099e"
}

import {
  to = aws_subnet.private["a"]
  id = "subnet-0f0592544418c4158"
}
import {
  to = aws_subnet.private["b"]
  id = "subnet-0f0e9fcc901acebcb"
}
import {
  to = aws_subnet.private["c"]
  id = "subnet-0aff7659aa5495879"
}
