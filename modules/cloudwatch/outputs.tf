output "django_log_group_name" {
  value = aws_cloudwatch_log_group.django_log_group.name
}

output "celery_log_group_name" {
  value = aws_cloudwatch_log_group.celery_log_group.name
}
