variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu AMI"
  type        = string
}

variable "key_name" {
  description = "EC2 SSH key pair"
  type        = string
}
