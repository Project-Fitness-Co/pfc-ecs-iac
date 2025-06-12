# ------------------------------------------------------------------------------
# Project Variables
# ------------------------------------------------------------------------------
variable "environment" {
  type        = string
  default     = ""
  description = "This is the Environment name for the resources."
}

variable "project" {
  type        = string
  description = "This is the Project name for which the resources are used."
}

variable "domain" {
  type        = string
  description = "This is the domain name for your Project."
}


# ------------------------------------------------------------------------------
# AWS Provider Variables
# ------------------------------------------------------------------------------
variable "aws_region" {
  type        = string
  description = "This is the AWS Region used for creating the Resources."
}

variable "aws_profile" {
  type        = string
  description = "This is the name of AWS profile to be configured with AWS provider."
}

variable "additonal_aws_tags" {
  type        = map(string)
  default     = {}
  description = "Key-Value map of tags to apply across all resources handled by AWS provider."
}


# ------------------------------------------------------------------------------
# API EC2 Instance Variables
# ------------------------------------------------------------------------------
variable "aws_ami_owner" {
  type        = string
  description = "This is owner used for filtering AWS AMI. Default is Amazon."
  default     = "amazon"
}

variable "aws_ami_name" {
  type        = string
  description = "This is name prefix used for filtering AWS AMI. Default is Amazon Linux 2 AMI with kernel 5.10."
  default     = "amzn2-ami-kernel-5.10-hvm-2.0.20220912.1-*"
}

variable "aws_ami_architecture" {
  type        = string
  description = "This is architecture used for filtering AWS AMI. Default is x86_64."
  default     = "x86_64"
}

variable "aws_ami_virtualization" {
  type        = string
  description = "This is virtualization-type used for filtering AWS AMI. Default is hvm."
  default     = "hvm"
}

variable "api_instance_type" {
  type        = string
  description = "This is the AWS EC2 Instance Type used for creating the API Server."
  default     = "t3.micro"
}

variable "api_url" {
  type        = string
  description = "This is the URL used for accessing the API Server."
  default     = ""
}

# ------------------------------------------------------------------------------
# Networking Variables
# ------------------------------------------------------------------------------
variable "vpc_id" {
  description = "Id of VPC used for existing project"
  type        = string
}


# ------------------------------------------------------------------------------
# Storage Variables
# ------------------------------------------------------------------------------
variable "redis_port" {
  description = "The redis port"
  default     = 6379
}

variable "redis_instance_class" {
  description = "The redis instance type"
  default     = "cache.t3.small"
}

variable "route_table_id" {
  description = "Route table id for private subnets"
}