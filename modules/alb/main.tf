
## Application Load Balancer Resources
## ------------------------------------------------------------------------------------------------------------
resource "aws_lb" "main_lb" {
  name                       = "${var.environment}-${var.project}-lb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = var.public_subnets_id
  security_groups            = [var.ecs_security_group_id]
  enable_deletion_protection = false
  idle_timeout               = 300
}

## Target group for backend
resource "aws_lb_target_group" "backend_target_group" {
  name                 = "${var.environment}-${var.project}-backend-tg"
  port                 = 5000
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path                = "/api/v1/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    timeout             = 120
    interval            = 200
    unhealthy_threshold = 2
    healthy_threshold   = 2
    matcher             = "200-499"
  }
  tags = {
    Name = "${var.environment}-${var.project}-backend-tg"
  }
}

## Load balancer listener
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.main_lb.arn
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "403"
      message_body = "Pfc"
    }

  }
  certificate_arn = var.aws_acm_load_balancer_arn
  depends_on      = [aws_lb_target_group.backend_target_group]
}

## Backend Routing
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.lb_listener.arn
  priority     = 90

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }

}

## Routing for django admin
resource "aws_lb_listener_rule" "backend_admin_rule" {
  listener_arn = aws_lb_listener.lb_listener.arn
  priority     = 92

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group.arn
  }

  condition {

    path_pattern {
      values = ["/admin4f2949a30501cc596f52a72de/*"]
    }
  }
}

