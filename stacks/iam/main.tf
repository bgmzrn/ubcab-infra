terraform {
  required_version = ">= 1.17.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}

module "constants" {
  source = "../.."
}

provider "aws" {
  region  = module.constants.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}
