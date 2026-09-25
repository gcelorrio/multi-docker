resource "random_password" "postgres" {
  length  = 24
  special = false
}

# Fuente de verdad del password: Secrets Manager. La instancia RDS y el
# entorno EB lo referencian a partir de aqui, no queda literal en el repo.
resource "aws_secretsmanager_secret" "postgres" {
  name = "${var.Terra_eb_app_name}/postgres"
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id     = aws_secretsmanager_secret.postgres.id
  secret_string = random_password.postgres.result
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.Terra_eb_app_name}-db"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "${var.Terra_eb_app_name}-db"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.Terra_eb_app_name}-postgres"
  engine                 = "postgres"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "postgres"
  username               = "postgres"
  password               = random_password.postgres.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Entorno solo de pruebas: sin alta disponibilidad ni backups.
  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true
}
