terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "awsfree"
}

resource "aws_security_group" "lab_sg" {
  name        = "terraform-lab-sg"
  description = "Allow SSH access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    # Later restrict this to your public IP
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-lab-sg"
  }
}

resource "aws_instance" "lab_server" {
  ami           = "ami-0e36589560a1853c7"
  instance_type = "t2.micro"

  key_name = "bdr-lab"

  vpc_security_group_ids = [aws_security_group.lab_sg.id]

  tags = {
    Name = "terraform-lab-server"
  }
}

output "public_ip" {
  value = aws_instance.lab_server.public_ip
}
