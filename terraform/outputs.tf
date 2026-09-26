output "environment_cname" {
  description = "URL publica del entorno Elastic Beanstalk"
  value       = aws_elastic_beanstalk_environment.this.cname
}

output "environment_name" {
  value = aws_elastic_beanstalk_environment.this.name
}

output "application_version_deployed" {
  value = aws_elastic_beanstalk_application_version.this.name
}

output "postgres_address" {
  value = aws_db_instance.postgres.address
}

output "redis_address" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}
