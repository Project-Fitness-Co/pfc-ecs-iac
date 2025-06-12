# PRIVATE SUBNETS AND NETWORKING
# ------------------------------------------------------------------------------

# Create 3 private subnets
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = var.vpc_id
  cidr_block        = ["172.31.48.0/20", "172.31.64.0/20", "172.31.80.0/20"][count.index]
  availability_zone = ["ap-south-1a", "ap-south-1b", "ap-south-1c"][count.index]

  tags = {
    Name        = "${var.environment}-${var.project}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project
    Type        = "Private"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
  
  tags = {
    Name        = "${var.environment}-${var.project}-nat-eip"
    Environment = var.environment
    Project     = var.project
  }
}

# NAT Gateway (placed in first public subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = var.public_subnets_id[0]
  
  tags = {
    Name        = "${var.environment}-${var.project}-nat-gateway"
    Environment = var.environment
    Project     = var.project
  }
  
  depends_on = [aws_eip.nat_gateway_eip]
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name        = "${var.environment}-${var.project}-private-rt"
    Environment = var.environment
    Project     = var.project
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
} 