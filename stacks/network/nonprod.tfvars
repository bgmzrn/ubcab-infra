name = "network"
env  = "nonprod"

aws_region  = "ap-southeast-1"
aws_profile = "bulgaa"

vpc_name             = "defaultSingapore"
vpc_secondary_cidrs  = ["172.30.0.0/16"]
enable_dns_support   = true
enable_dns_hostnames = true

public_subnets = {
  a = {
    cidr_block = "172.31.0.0/18"
    az         = "ap-southeast-1a"
    name       = "publicA"
  }
  b = {
    cidr_block = "172.31.64.0/19"
    az         = "ap-southeast-1b"
    name       = "publicB"
  }
  c = {
    cidr_block = "172.31.96.0/19"
    az         = "ap-southeast-1c"
    name       = "publicC"
  }
}

private_subnets = {
  a = {
    cidr_block = "172.31.128.0/18"
    az         = "ap-southeast-1a"
    name       = "privateA"
  }
  b = {
    cidr_block = "172.31.192.0/19"
    az         = "ap-southeast-1b"
    name       = "privateB"
  }
  c = {
    cidr_block = "172.31.224.0/19"
    az         = "ap-southeast-1c"
    name       = "privateC"
  }
}
