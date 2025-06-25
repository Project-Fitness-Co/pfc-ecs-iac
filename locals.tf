locals {
  aws_availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
}

locals {
  aws_default_tags = {
    Environment = var.environment != "" ? "${var.environment}" : "Production"
    Project     = var.project != "" ? "${var.project}" : "PFC"
    managedBy   = "Terraform",
  }
}
