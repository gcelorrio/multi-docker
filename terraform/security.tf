resource "aws_security_group" "eb" {
  name        = "${var.Terra_eb_app_name}-eb"
  description = "Instancias de Elastic Beanstalk"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.Terra_eb_app_name}-eb"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.Terra_eb_app_name}-rds"
  description = "Postgres, solo accesible desde las instancias de EB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres desde EB"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.Terra_eb_app_name}-rds"
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.Terra_eb_app_name}-redis"
  description = "Redis, solo accesible desde las instancias de EB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis desde EB"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.Terra_eb_app_name}-redis"
  }
}
