variable "environment" {
  description = "The environment"
}

variable "project" {
  description = "Project name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ids to use for RDS and Redis"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "redis_instance_class" {
  description = "The redis instance type"
  default     = "cache.t3.small"
}

variable "redis_port" {
  description = "The Redis port"
}