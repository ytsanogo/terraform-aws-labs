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

resource "aws_security_group" "lab_sg" {
  name        = "terraform-lab4-sg"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH"

    from_port = 22
    to_port   = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lab_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = [aws_security_group.lab_sg.id]

  user_data = <<-EOF
              #!/bin/bash

              apt-get update -y

              apt-get install -y nginx htop

              systemctl enable nginx
              systemctl start nginx

              echo "Terraform user_data automation works" > /var/www/html/index.html

              EOF

  tags = {
    Name = "terraform-lab4-server"
  }
}
