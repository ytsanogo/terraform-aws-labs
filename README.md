# Terraform AWS Labs 1–7 Complete Hands-On Guide

## Overview

This guide walks through a complete beginner-to-intermediate Terraform learning path on AWS using:

* Windows 11
* Git Bash
* AWS CLI
* Terraform
* AWS Free Tier
* EC2
* S3
* Security Groups
* Variables
* Outputs
* User Data
* VPC networking

The labs are designed to build real Infrastructure as Code (IaC) skills progressively.

---

# Initial Prerequisites

## Verify AWS CLI

```bash
aws --version
```

## Verify Terraform

```bash
terraform --version
```

## Configure AWS Profile

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

## Export AWS Profile

```bash
export AWS_PROFILE=awsfree
```

Verify:

```bash
aws sts get-caller-identity
```

---

# Git Bash Terraform PATH Fix

Add Terraform permanently to Git Bash PATH:

```bash
echo 'export PATH=$PATH:/c/ProgramData/chocolatey/bin' >> ~/.bashrc
source ~/.bashrc
```

Verify:

```bash
terraform --version
```

---

# LAB 1 — S3 Bucket

## Goal

Learn Terraform fundamentals:

* provider
* resource
* init
* validate
* plan
* apply
* destroy

---

## Create Lab Directory

```bash
mkdir -p ~/terraform-labs/lab1-s3
cd ~/terraform-labs/lab1-s3
```

---

## Create main.tf

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

## Terraform Workflow

### Initialize

```bash
terraform init
```

### Validate

```bash
terraform validate
```

### Plan

```bash
terraform plan
```

### Apply

```bash
terraform apply
```

Type:

```text
yes
```

---

## Verify Bucket

```bash
aws s3 ls
```

---

## Destroy Infrastructure

```bash
terraform destroy
```

Type:

```text
yes
```

---

# LAB 2 — EC2 + Security Group

## Goal

Create:

* EC2 instance
* Security Group
* SSH access

---

## Create Lab Directory

```bash
mkdir -p ~/terraform-labs/lab2-ec2
cd ~/terraform-labs/lab2-ec2
```

Copy lock file:

```bash
cp ../lab1-s3/.terraform.lock.hcl .
```

---

## Create main.tf

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

  tags = {
    Name = "terraform-lab-sg"
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

## Terraform Workflow

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

---

## SSH into Server

```bash
chmod 400 ~/.ssh/bdr-lab-key.pem
```

```bash
ssh -i ~/.ssh/bdr-lab-key.pem ubuntu@$(terraform output -raw public_ip)
```

---

## Destroy Resources

```bash
terraform destroy
```

---

# LAB 3 — Variables + Outputs

## Goal

Learn reusable Terraform configuration using:

* variables
* tfvars
* outputs

---

## Create Lab Directory

```bash
mkdir -p ~/terraform-labs/lab3-variables
cd ~/terraform-labs/lab3-variables
```

Copy lock file and provider cache:

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

## Run Terraform

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

---

# LAB 4 — User Data Bootstrap Automation

## Goal

Automatically configure EC2 during boot.

Learn:

* user_data
* bootstrap automation
* package installation
* service startup

---

## Create Lab Directory

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
  name        = "terraform-lab4-sg"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
cat /var/www/html/index.html
```

Open browser:

```text
http://PUBLIC_IP
```

---

# LAB 5 — Terraform Locals

## Goal

Learn:

* locals
* reusable naming
* centralized values

---

## Create locals.tf

```hcl
locals {
  project_name = "terraform-lab5"
  common_tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}
```

---

## Use Locals in Resources

Example:

```hcl
tags = merge(local.common_tags, {
  Name = "terraform-lab5-server"
})
```

---

# LAB 6 — Remote State with S3 Backend

## Goal

Learn production-grade Terraform state management.

---

## Create S3 Backend Bucket

```bash
aws s3 mb s3://terraform-state-youssouf-2026 --profile awsfree
```

---

## Create backend.tf

```hcl
terraform {
  backend "s3" {
    bucket  = "terraform-state-youssouf-2026"
    key     = "lab6/terraform.tfstate"
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

Type:

```text
yes
```

Terraform migrates local state to S3.

---

# LAB 7 — VPC Networking

## Goal

Learn AWS networking fundamentals.

Create:

* VPC
* Public subnet
* Internet Gateway
* Route Table
* Route Association
* Security Group
* EC2 instance

---

## Create Lab Directory

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

  tags = {
    Name = "terraform-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "terraform-public-rt"
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

## Run Terraform

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

---

## SSH into Instance

```bash
ssh -i ~/.ssh/bdr-lab-key.pem ubuntu@$(terraform output -raw public_ip)
```

---

# Final Cleanup

Destroy resources after every lab:

```bash
terraform destroy
```

Type:

```text
yes
```

---

# Skills Learned Across Labs

## Terraform

* providers
* resources
* variables
* outputs
* locals
* state management
* remote backend
* execution plan
* lifecycle management

## AWS

* S3
* EC2
* Security Groups
* VPC
* Subnets
* Route Tables
* Internet Gateway
* SSH
* User Data

## DevOps Concepts

* Infrastructure as Code
* immutable infrastructure
* bootstrap automation
* reusable infrastructure
* cloud networking
* infrastructure lifecycle
* reproducibility
* environment standardization

---

# Publish This Project to GitHub

## Create Local Git Repository

From the root Terraform labs directory:

```bash
cd ~/terraform-labs

git init
```

---

## Create README.md

Copy this document content into:

```bash
README.md
```

---

## Create .gitignore

Create:

```bash
touch .gitignore
```

Add:

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

# OS
.DS_Store
Thumbs.db
```

---

## Commit Repository

```bash
git add .
git commit -m "Initial Terraform AWS Labs"
```

---

## Create GitHub Repository

Suggested repository name:

```text
terraform-aws-labs
```

Suggested description:

```text
Hands-on Terraform AWS labs covering EC2, S3, VPCs, variables, outputs, remote state, and Infrastructure as Code workflows.
```

---

## Connect Local Repo to GitHub

Example:

```bash
git remote add origin https://github.com/YOUR_USERNAME/terraform-aws-labs.git
```

---

## Push to GitHub

```bash
git branch -M main

git push -u origin main
```

---

## Important Security Notes

Never commit:

* AWS credentials
* .pem files
* terraform.tfstate
* terraform.tfvars containing secrets

Use:

* environment variables
* AWS profiles
* secrets managers
* remote Terraform state

---

# Recommended Next Topics

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

