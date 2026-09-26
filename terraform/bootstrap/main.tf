terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State local, intencionadamente: este config crea el propio bucket que
  # el resto de terraform/ usará como backend remoto. No tiene sentido
  # remoto para si mismo.
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = {
    Name    = var.state_bucket_name
    Purpose = "terraform-state-and-deploy-artifacts"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Elastic Beanstalk reutiliza este mismo bucket (nombre reservado
# elasticbeanstalk-<region>-<account-id>) como su storage interno de entorno,
# y necesita poder usar ACLs sobre el. El "Bucket owner enforced" (deshabilita
# ACLs) que trae S3 por defecto desde 2023 rompe la creacion del entorno con
# "the bucket does not allow ACLs".
resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
