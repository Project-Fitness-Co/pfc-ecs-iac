variable "environment" {
  description = "Environment for the resources"
  # Change statefile accordingly
}

variable "project" {
  description = "Project Name"
}

variable "vpc_id" {
  description = "vpc id for pfc"
}

variable "aws_region" {
  description = "AWs region for resources"
}

variable "django_port" {
  default = "5000"
  type    = number
}

variable "elasticache_address" {
  description = "Elasticache instance address"
}

variable "django_ecr_url" {
  description = "AWS ecr url for django"
}

variable "public_subnets_id" {
  description = "subnet id for vpc"
}

variable "django_log_group_name" {
  description = "Cloudwatch log group name for django task"
}

variable "celery_log_group_name" {
  description = "Cloudwatch log group name for django task"
}

variable "django_target_group_arn" {
  description = "ARN for backend target group"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs from networking module"
  type        = list(string)
}