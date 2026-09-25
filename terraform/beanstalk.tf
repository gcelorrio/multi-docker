# Plataforma Docker soportada actual (AL2023). Se resuelve por regex en vez
# de fijar el nombre exacto: AWS revisa estos nombres con cada actualización
# menor y los branches AL2 quedaron retirados el 6 de agosto de 2026.
data "aws_elastic_beanstalk_solution_stack" "docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023.*running Docker$"
}

resource "aws_elastic_beanstalk_application" "this" {
  name = var.Terra_eb_app_name
}

# Mismo bucket que el backend de Terraform, bajo un prefijo propio.
resource "aws_s3_object" "deploy_package" {
  bucket = var.Terra_state_bucket
  key    = "${var.Terra_eb_app_name}/deploy-${var.Terra_version_label}.zip"
  source = var.Terra_deploy_package_path
  etag   = filemd5(var.Terra_deploy_package_path)
}

resource "aws_elastic_beanstalk_application_version" "this" {
  name        = var.Terra_version_label
  application = aws_elastic_beanstalk_application.this.name
  bucket      = aws_s3_object.deploy_package.bucket
  key         = aws_s3_object.deploy_package.key
}

resource "aws_elastic_beanstalk_environment" "this" {
  name                = var.Terra_eb_env_name
  application         = aws_elastic_beanstalk_application.this.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.docker.name
  tier                = "WebServer"
  version_label       = aws_elastic_beanstalk_application_version.this.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service.name
  }

  # Entorno solo de pruebas: instancia única, sin Auto Scaling ni ELB,
  # para no incurrir en ese coste.
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", aws_subnet.public[*].id)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REDIS_HOST"
    value     = aws_elasticache_cluster.redis.cache_nodes[0].address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REDIS_PORT"
    value     = "6379"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGUSER"
    value     = aws_db_instance.postgres.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGPASSWORD"
    value     = random_password.postgres.result
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGHOST"
    value     = aws_db_instance.postgres.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGDATABASE"
    value     = aws_db_instance.postgres.db_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGPORT"
    value     = "5432"
  }

  depends_on = [
    aws_db_instance.postgres,
    aws_elasticache_cluster.redis,
    aws_iam_instance_profile.eb_ec2,
    aws_iam_role_policy_attachment.eb_service_health,
    aws_iam_role_policy_attachment.eb_service_updates,
  ]
}
