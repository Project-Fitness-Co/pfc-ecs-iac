variable "environment" {
  description = "Environment for the resources"
  # Change statefile accordingly
}

variable "project" {
  description = "Project Name"
}

variable "public_subnets_id" {
  description = "subnet id for vpc"
}

variable "vpc_id" {
  description = "vpc id for pfc"
}

variable "aws_acm_load_balancer_arn" {
  description = "ARN for load balancer certiicate"
}

variable "ecs_security_group_id" {
  description = "ECS cluster's security group ID"
}

