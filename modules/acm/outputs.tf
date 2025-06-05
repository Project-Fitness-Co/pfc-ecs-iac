output "aws_acm_load_balancer_arn" {
  value = aws_acm_certificate.lb_api.arn
}