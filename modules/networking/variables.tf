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


# variable "vpc_cidr" {
#   description = "The CIDR block of the vpc"
# }

# variable "public_subnets_cidr" {
#   type        = list(string)
#   description = "The CIDR block for the public subnet"
# }

# variable "private_subnets_cidr" {
#   type        = list(string)
#   description = "The CIDR block for the private subnet"
# }

# variable "environment" {
#   description = "Envieonment for the resources"
#   # Change statefile accordingly
# }


# variable "region" {
#   description = "The region to launch the bastion host"
# }

variable "aws_availability_zones" {
  type        = list(string)
  description = "The az that the resources will be launched"
}
