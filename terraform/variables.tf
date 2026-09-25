# --- Variables inyectadas desde GitHub Actions (prefijo Terra_) ---

variable "Terra_aws_region" {
  description = "Región AWS donde se despliega la infraestructura"
  type        = string
}

variable "Terra_eb_app_name" {
  description = "Nombre de la aplicación Elastic Beanstalk"
  type        = string
}

variable "Terra_eb_env_name" {
  description = "Nombre del entorno Elastic Beanstalk"
  type        = string
}

variable "Terra_version_label" {
  description = "Etiqueta de versión desplegada (github.sha)"
  type        = string
}

variable "Terra_deploy_package_path" {
  description = "Ruta local al deploy.zip generado por el job de CI"
  type        = string
}

variable "Terra_state_bucket" {
  description = "Bucket S3 (creado por terraform/bootstrap) usado como backend y para subir el deploy.zip"
  type        = string
}

# --- Configuración de infraestructura, con valores por defecto para el entorno de pruebas ---

variable "vpc_cidr" {
  description = "CIDR de la VPC del entorno de pruebas"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_instance_class" {
  description = "Tipo de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "cache_node_type" {
  description = "Tipo de nodo ElastiCache"
  type        = string
  default     = "cache.t3.micro"
}
