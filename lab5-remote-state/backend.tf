terraform {
  backend "s3" {
    bucket  = "youssouf-terraform-state-2026"
    key     = "lab5/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true

    # Modern native S3 state locking
    use_lockfile = true
  }
}

