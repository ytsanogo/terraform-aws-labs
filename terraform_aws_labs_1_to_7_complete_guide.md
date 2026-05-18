# Terraform AWS Labs 1–7 — Complete Clean Project Guide

## Project Overview

This project is a complete hands-on Terraform learning path designed for AWS Free Tier environments using:

- Windows 11
- Git Bash
- AWS CLI
- Terraform
- GitHub
- EC2
- S3
- VPC networking

The goal is to build real Infrastructure as Code (IaC) skills progressively while following safe DevOps and cloud engineering practices.

---

# Local Environment Setup

## Verify AWS CLI

```bash
aws --version
```

## Verify Terraform

```bash
terraform --version
```

## Configure AWS CLI

### ~/.aws/config

```ini
[default]
region = us-east-1
output = json

[profile awsfree]
region = us-east-1
output = json
```

### ~/.aws/credentials

```ini
[awsfree]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

---

# Git Bash Terraform PATH Configuration

## Add Terraform to PATH Permanently

```bash
echo 'export PATH=$PATH:/c/ProgramData/chocolatey/bin' >> ~/.bashrc
source ~/.bashrc
```

Verify:

```bash
terraform --version
```

---

# AWS Authentication

Export the AWS profile before running Terraform:

```bash
export AWS_PROFILE=awsfree
```

Verify:

```bash
aws sts get-caller-identity
```

---

# Terraform Workflow Fundamentals

Every Terraform lab follows the same lifecycle:

```text
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

This is the foundation of Infrastructure as Code.

---

# LAB 1 — S3 Bucket

## Objective

Learn basic Terraform concepts:

- provider
- resource
- init
- validate
- plan
- apply
- destroy

---

## Create Project Directory

```bash
mkdir -p ~/terraform-labs/lab1-s3
cd ~/terraform-labs/lab1-s3
```

---

## main.tf

```hcl
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

resource "aws_s3_bucket" "lab_bucket" {
  bucket = "tf-lab-youssouf-2026"
}
```

---

## Run Terraform

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Type:

```text
yes
```

Verify:

```bash
aws s3 ls
```

Destroy:

```bash
terraform destroy
```

---

# LAB 2 — EC2 + Security Group

## Objective

Create:

- EC2 instance
- Security Group
- SSH access

---

## Create Project Directory

```bash
mkdir -p ~/terraform-labs/lab2-ec2
cd ~/terraform-labs/lab2-ec2
```

Copy provider lock file:

```bash
cp ../lab1-s3/.terraform.lock.hcl .
```

---

## main.tf

```hcl
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

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lab_server" {
  ami           = "ami-084568db4383264d4"
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
```

---

## SSH into Instance

```bash
chmod 400 ~/.ssh/bdr-lab-key.pem
```

```bash
ssh -i ~/.ssh/bdr-lab-key.pem ubuntu@$(terraform output -raw public_ip)
```

Destroy resources when finished:

```bash
terraform destroy
```

---

# LAB 3 — Variables + Outputs

## Objective

Learn reusable Terraform configuration using:

- variables
- tfvars
- outputs

---

## Create Project Directory

```bash
mkdir -p ~/terraform-labs/lab3-variables
cd ~/terraform-labs/lab3-variables
```

Copy provider files:

```bash
cp ../lab2-ec2/.terraform.lock.hcl .
cp -r ../lab2-ec2/.terraform .
```

---

## Create Files

```bash
touch main.tf variables.tf terraform.tfvars outputs.tf
```

---

## variables.tf

```hcl
variable "aws_region" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "key_name" {
  type = string
}
```

---

## terraform.tfvars

```hcl
aws_region    = "us-east-1"
instance_type = "t2.micro"
ami_id         = "ami-084568db4383264d4"
key_name       = "bdr-lab"
```

---

## outputs.tf

```hcl
output "public_ip" {
  value = aws_instance.lab_server.public_ip
}

output "instance_id" {
  value = aws_instance.lab_server.id
}

output "availability_zone" {
  value = aws_instance.lab_server.availability_zone
}
```

---

## main.tf

```hcl
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
  name        = "terraform-lab3-sg"
  description = "Allow SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lab_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = [aws_security_group.lab_sg.id]

  tags = {
    Name = "terraform-lab3-server"
  }
}
```

---

# LAB 4 — User Data Automation

## Objective

Automatically configure EC2 during boot using user_data.

Learn:

- bootstrap automation
- package installation
- service startup
- server provisioning

---

## Create Project Directory

```bash
mkdir -p ~/terraform-labs/lab4-userdata
cd ~/terraform-labs/lab4-userdata
```

Copy provider cache:

```bash
cp ../lab3-variables/.terraform.lock.hcl .
cp -r ../lab3-variables/.terraform .
```

---

## main.tf

```hcl
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
  name        = "terraform-lab4-sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lab_server" {
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.micro"

  key_name = "bdr-lab"

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

output "public_ip" {
  value = aws_instance.lab_server.public_ip
}
```

---

## Verify Automation

SSH into server:

```bash
ssh -i ~/.ssh/bdr-lab-key.pem ubuntu@$(terraform output -raw public_ip)
```

Verify:

```bash
systemctl status nginx
```

```bash
cat /var/www/html/index.html
```

Open browser:

```text
http://PUBLIC_IP
```

---

# LAB 5 — Remote Terraform State

## Objective

Learn production-style remote Terraform state management.

---

## Create S3 Backend Bucket

```bash
aws s3 mb s3://terraform-state-youssouf-2026 --profile awsfree
```

---

## backend.tf

```hcl
terraform {
  backend "s3" {
    bucket  = "terraform-state-youssouf-2026"
    key     = "lab5/terraform.tfstate"
    region  = "us-east-1"
    profile = "awsfree"
  }
}
```

---

## Initialize Backend

```bash
terraform init
```

Terraform migrates local state to S3.

---

# LAB 6 — Terraform Modules

## Objective

Learn reusable Terraform architecture using modules.

---

## Suggested Structure

```text
lab6-modules/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    └── ec2/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Example Module Usage

```hcl
module "ec2_server" {
  source = "./modules/ec2"

  ami_id        = "ami-084568db4383264d4"
  instance_type = "t2.micro"
  key_name      = "bdr-lab"
}
```

---

# LAB 7 — VPC Networking

## Objective

Learn AWS networking fundamentals.

Create:

- VPC
- Public subnet
- Internet Gateway
- Route Table
- Route Association
- Security Group
- EC2 instance

---

## Create Project Directory

```bash
mkdir -p ~/terraform-labs/lab7-vpc
cd ~/terraform-labs/lab7-vpc
```

---

## main.tf

```hcl
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

resource "aws_vpc" "lab_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-lab-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "lab_sg" {
  name        = "terraform-vpc-sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lab_server" {
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.public_subnet.id

  key_name = "bdr-lab"

  vpc_security_group_ids = [aws_security_group.lab_sg.id]

  tags = {
    Name = "terraform-vpc-server"
  }
}

output "public_ip" {
  value = aws_instance.lab_server.public_ip
}
```

---

# GitHub Repository Setup

## Initialize Git Repository

```bash
git init
```

---

## Create .gitignore

```gitignore
# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraform.lock.hcl

# Sensitive files
*.pem
*.key

# AWS
.aws/
credentials
config

# Environment
.env
.env.*

# IDE
.vscode/
.idea/
```

---

## Verify Sensitive Files Are Ignored

```bash
git status --ignored
```

---

## Commit Repository

```bash
git add .
git status
git commit -m "Initial Terraform AWS Labs"
```

---

## Push to GitHub

```bash
git remote add origin https://github.com/YOUR_USERNAME/terraform-aws-labs.git
```

```bash
git branch -M main
```

```bash
git push -u origin main
```

---

# Security Best Practices

Never commit:

- AWS credentials
- .pem files
- terraform.tfstate
- terraform.tfvars containing secrets
- internal company infrastructure
- internal scripts
- production IP addresses

Always verify before commit:

```bash
git status
```

---

# Skills Learned

## Terraform

- providers
- resources
- variables
- outputs
- modules
- remote state
- execution plans
- lifecycle management

## AWS

- S3
- EC2
- Security Groups
- VPC
- Subnets
- Internet Gateway
- Route Tables
- SSH
- User Data

## DevOps Concepts

- Infrastructure as Code
- immutable infrastructure
- bootstrap automation
- reusable infrastructure
- remote state management
- environment standardization
- cloud networking
- infrastructure lifecycle

---

# Recommended Next Topics

1. DynamoDB State Locking
2. GitHub Actions for Terraform
3. Packer + Terraform
4. Launch Templates
5. Auto Scaling Groups
6. IAM Roles
7. CloudWatch
8. Load Balancers
9. Multi-Environment Deployments
10. Kubernetes Infrastructure

1. Terraform Modules
2. DynamoDB State Locking
3. Packer + Terraform
4. GitHub Actions
5. Multi-Environment Structure
6. Auto Scaling Groups
7. Load Balancers
8. IAM Roles
9. CloudWatch
10. Kubernetes

