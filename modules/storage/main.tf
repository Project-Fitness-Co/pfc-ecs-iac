# Elasticache - Redis
# ------------------------------------------------------------------------------

resource "aws_security_group" "redis-security-group" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = var.redis_port
    to_port     = var.redis_port
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
    name = "${var.environment}-${var.project}-redis-security-group"
  }
}

resource "aws_elasticache_subnet_group" "elasti-subnets" {
  name       = "${var.environment}-${var.project}-redis-cache-subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.environment}-${var.project}-redis"
  engine               = "redis"
  node_type            = var.redis_instance_class
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.elasti-subnets.name
  security_group_ids   = [aws_security_group.redis-security-group.id]
  tags = {
    name = "${var.environment}-${var.project}-redis"
  }
}

# ECR repo for django
# ------------------------------------------------------------------------------
resource "aws_ecr_repository" "pfc_django" {
  name                 = "${var.environment}-${var.project}-django"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
