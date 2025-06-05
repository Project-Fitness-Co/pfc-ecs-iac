output "django_target_group_arn" {
  value       = aws_lb_target_group.backend_target_group.arn
  description = "ARN for backend target group"
}
