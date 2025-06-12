data "aws_internet_gateway" "ig" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}