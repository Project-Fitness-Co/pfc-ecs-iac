resource "aws_cloudwatch_log_group" "django_log_group" {
  name              = "/pfc-ecs/django"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "celery_log_group" {
  name              = "/pfc-ecs/celery-worker"
  retention_in_days = 30
}
