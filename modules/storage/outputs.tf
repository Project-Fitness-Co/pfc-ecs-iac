output "redis_address" {
  value = aws_elasticache_cluster.redis.cache_nodes.0.address
}

output "ecr_url" {
  value = aws_ecr_repository.pfc_django.repository_url
}

