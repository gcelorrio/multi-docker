resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.Terra_eb_app_name}-cache"
  subnet_ids = aws_subnet.public[*].id
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.Terra_eb_app_name}-redis"
  engine               = "valkey"
  engine_version       = "7.2"
  node_type            = var.cache_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.valkey7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]

  # Entorno solo de pruebas: sin snapshots.
  snapshot_retention_limit = 0
}
