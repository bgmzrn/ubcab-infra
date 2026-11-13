name = "network"
env  = "nonprod"

vpc_name             = "defaultSingapore"
vpc_secondary_cidr   = "172.30.0.0/16"
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

private_subnet_extra_tags = {
  "kubernetes.io/cluster/pulsar"    = "shared"
  "kubernetes.io/role/internal-elb" = "1"
}

import_aws_default_vpc_main = "vpc-0e4c0c5f87416d4f6"

import_aws_vpc_ipv4_cidr_block_association_secondary = "vpc-cidr-assoc-0743e2c4386d3d314"

import_public_subnets = {
  a = "subnet-02ff1de080131916a"
  b = "subnet-0662fa61fbc36cfbb"
  c = "subnet-067873761256b099e"
}

import_private_subnets = {
  a = "subnet-0f0592544418c4158"
  b = "subnet-0f0e9fcc901acebcb"
  c = "subnet-0aff7659aa5495879"
}
