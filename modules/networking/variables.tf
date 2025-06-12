variable "environment" {
  description = "Environment for the resources"
  type        = string
}

variable "project" {
  description = "Project Name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "public_subnets_id" {
  description = "List of public subnet IDs for NAT Gateway placement"
  type        = list(string)
} 