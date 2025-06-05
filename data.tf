# Fetch available subnets in the specified VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Get details of the first public subnet
data "aws_subnet" "selected" {
  id = tolist(data.aws_subnets.public.ids)[0]
}