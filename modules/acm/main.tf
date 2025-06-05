## ACM CERTIFICATE FOR APPLICATION LOAD BALANCER
## ------------------------------------------------------------------------------------------------------------
resource "aws_acm_certificate" "lb_api" {
  domain_name       = "backend.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.environment}-${var.project}-certificate"
    Environment = var.environment
  }
}
