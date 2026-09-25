variable "aws_region" {
  description = "Región AWS donde se crea el bucket"
  type        = string
  default     = "eu-west-3"
}

variable "state_bucket_name" {
  description = "Nombre único global del bucket S3 (backend de Terraform + deploy.zip)"
  type        = string
}
