import {
  to = aws_security_group.web_server
  id = "sg-035801f30d23d0c1f"
}

import {
  to = aws_vpc_security_group_ingress_rule.web_server_http
  id = "sgr-0da3d1045280eba7f"
}
import {
  to = aws_vpc_security_group_ingress_rule.web_server_https
  id = "sgr-0f99655ce3d237a19"
}
import {
  to = aws_vpc_security_group_ingress_rule.web_server_ssh["mezorn"]
  id = "sgr-0279743d5cf61b243"
}
import {
  to = aws_vpc_security_group_ingress_rule.web_server_ssh["boldoo"]
  id = "sgr-0ca58b060964a69f7"
}
import {
  to = aws_vpc_security_group_egress_rule.web_server_all
  id = "sgr-000f3619117e0a01c"
}

import {
  to = aws_security_group.nat
  id = "sg-04ffc8b94faa407ca"
}

import {
  to = aws_vpc_security_group_ingress_rule.nat_private["a"]
  id = "sgr-0994cccf188772ca0"
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_private["b"]
  id = "sgr-007fc5a52a60a0785"
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_private["c"]
  id = "sgr-0619c1887e6f76fad"
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_ssh["office"]
  id = "sgr-09f75944ecacebdbb"
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_ssh["office_mobinet"]
  id = "sgr-09ff03010bc8836e3"
}
import {
  to = aws_vpc_security_group_ingress_rule.nat_ssh["office_alt"]
  id = "sgr-0715c4562362dcb50"
}
import {
  to = aws_vpc_security_group_egress_rule.nat_all
  id = "sgr-00b8e0eed8e531f59"
}

import {
  to = aws_security_group.mysql
  id = "sg-0619243182b900919"
}

import {
  to = aws_vpc_security_group_ingress_rule.mysql_from_nat
  id = "sgr-064a8062542e198b7"
}
import {
  to = aws_vpc_security_group_ingress_rule.mysql_from_web_server
  id = "sgr-0da160c69dbfd1bf1"
}
import {
  to = aws_vpc_security_group_egress_rule.mysql_all
  id = "sgr-0940677cfd2f13926"
}

import {
  to = aws_security_group.private_ssh
  id = "sg-0d052b88ef17de5fd"
}

import {
  to = aws_vpc_security_group_ingress_rule.private_ssh_cidr["host"]
  id = "sgr-0d400de3117d944e8"
}
import {
  to = aws_vpc_security_group_ingress_rule.private_ssh_from_nat
  id = "sgr-08df9c4da13e2a242"
}
import {
  to = aws_vpc_security_group_egress_rule.private_ssh_https
  id = "sgr-0646ad22eb190bd45"
}
import {
  to = aws_vpc_security_group_egress_rule.private_ssh_all
  id = "sgr-0f9cf5dca4741a562"
}

import {
  to = aws_default_security_group.default
  id = "sg-037d60015e8ac3b5c"
}
