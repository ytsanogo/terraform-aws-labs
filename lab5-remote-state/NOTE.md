# Lab 5 Notes: Remote State

This lab configures Terraform to store state remotely in an S3 bucket.

## Backend

The remote backend is configured in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket       = "youssouf-terraform-state-2026"
    key          = "lab5/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

The backend bucket is:

```text
youssouf-terraform-state-2026
```

## Normal Workflow

Use the AWS profile for this lab:

```bash
export AWS_PROFILE=awsfree
```

Initialize Terraform:

```bash
terraform init -reconfigure
```

Check the plan:

```bash
terraform plan
```

Apply only when the plan looks correct:

```bash
terraform apply
```

## Important

Do not run `terraform destroy` casually in this lab. The S3 bucket is used as the remote state backend, so deleting it can remove the place where Terraform stores its state.

If the bucket already exists but Terraform wants to create it, import it first:

```bash
terraform import aws_s3_bucket.tf_state youssouf-terraform-state-2026
terraform import aws_s3_bucket_versioning.tf_state_versioning youssouf-terraform-state-2026
terraform plan
```

When the configuration is correct, `terraform plan` should show:

```text
No changes. Your infrastructure matches the configuration.
```
