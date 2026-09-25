terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Backend parcial: bucket/key/region se inyectan en `terraform init`
  # vía -backend-config desde el job de GitHub Actions (o a mano en local).
  # use_lockfile usa el locking nativo de S3 (Terraform >= 1.10), sin DynamoDB.
  backend "s3" {
    use_lockfile = true
  }
}

provider "aws" {
  region = var.Terra_aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}
