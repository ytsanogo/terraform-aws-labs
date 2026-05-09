terraform {
  backend "s3" {
    bucket         = "youssouf-terraform-state-2026"
    key            = "lab5/terraform.tfstate"
    region         = "us-east-1"
    profile        = "awsfree"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
