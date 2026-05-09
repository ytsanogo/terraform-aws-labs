terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "awsfree"
}

module "ec2_web" {
  source = "./modules/ec2-web"

  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
}
