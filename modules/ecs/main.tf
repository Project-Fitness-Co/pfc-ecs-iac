# S3 bucket for Django Secrets
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "backend_secrets" {
  bucket = "${var.environment}-${var.project}-backend-secrets"

  tags = {
    Name = "${var.environment}-${var.project}-backend-secrets"
  }

}

resource "aws_s3_bucket_ownership_controls" "backend_secrets_acl_ownership" {
  bucket = aws_s3_bucket.backend_secrets.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "backend_secrets_acl" {
  bucket     = aws_s3_bucket.backend_secrets.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.backend_secrets_acl_ownership]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend_secrets_encryption" {
  bucket = aws_s3_bucket.backend_secrets.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

## Upload env text file to the created S3 bucket
resource "aws_s3_object" "django-secrets" {
  bucket = aws_s3_bucket.backend_secrets.id
  key    = "secrets/production-pfc-secrets.env"
  source = "./modules/ECS/.envs/production-pfc-djangosecrets.env"
  acl    = "private"
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}


# ECS CLUSTER CONFIGURATION
# ------------------------------------------------------------------------------

## ECS CLUSTER
resource "aws_ecs_cluster" "pfc-cluster" {
  name = "${var.environment}-${var.project}-ecs-cluster"
  lifecycle {
    create_before_destroy = true
  }

  # disabled to save costs
  # setting {
  #   name  = "containerInsights"
  #   value = "enabled"
  # }
  tags = {
    Environment = var.environment
    Project     = var.project
  }

}

# SECURITY GROUPS
# ------------------------------------------------------------------------------

## Security group for ECS cluster access 
resource "aws_security_group" "pfc-cluster-sg" {
  name        = "${var.environment}-${var.project}-ecs-cluster-sg"
  description = "Security group for ecs cluster"
  vpc_id      = var.vpc_id

  # Allow inbound HTTP traffic
  ingress {
    description = "Allow inbound HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS traffic
  ingress {
    description = "Allow inbound HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS traffic
  ingress {
    description = "Allow inbound Django traffic"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
## Security Group for EC2 instances in ECS cluster
resource "aws_security_group" "ec2" {
  name        = "${var.environment}-${var.project}-EC2-Instance-sg"
  description = "Security group for EC2 instances in ECS cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH ingress traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS ingress traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Django ingress traffic"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow RDS ingress traffic"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow pgbouncer ingress traffic"
    from_port   = 6432
    to_port     = 6432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow NFS traffic"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow ingress from http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = [var.rds_security_group_id]
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Autoscaling Group
# ------------------------------------------------------------------------------
# Creates an ASG linked with our main VPC

resource "aws_autoscaling_group" "ecs-autoscaling-group" {

  name                      = "${var.environment}-${var.project}-asg"
  max_size                  = 5
  min_size                  = 1
  vpc_zone_identifier       = var.public_subnets_id
  health_check_type         = "EC2"
  protect_from_scale_in     = false
  health_check_grace_period = 90
  desired_capacity          = 2
  termination_policies      = ["OldestLaunchConfiguration"]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id      = aws_launch_template.ecs-launch-template.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      skip_matching          = true
    }
    triggers = []
  }

  # lifecycle {
  #   create_before_destroy = true
  # }

  tag {
    key                 = "Name"
    value               = "${var.project}_ASG_${var.environment}"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project
    propagate_at_launch = true
  }
  depends_on = [aws_ecs_cluster.pfc-cluster]
}


# Creates Capacity Provider linked with ASG and ECS Cluster

resource "aws_ecs_capacity_provider" "pfc-cas" {
  name = "${var.environment}-${var.project}-ECS-CapacityProvider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs-autoscaling-group.arn
    managed_termination_protection = "DISABLED" //CHANGE THIS LATER

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
  tags = {
    Environment = var.environment
    Project     = var.project
  }
  depends_on = [aws_ecs_cluster.pfc-cluster]
}

resource "aws_ecs_cluster_capacity_providers" "pfc-cas" {
  cluster_name       = aws_ecs_cluster.pfc-cluster.name
  capacity_providers = [aws_ecs_capacity_provider.pfc-cas.name]
}

# EC2 IINSTANCES CONFIGURATION
# ------------------------------------------------------------------------------

# Keypair for ec2 intances
# Generate an SSH key pair
resource "tls_private_key" "pfc_ecs_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "pfc_ecs_key" {
  key_name   = "${var.environment}-${var.project}-ecs-keypair"
  public_key = tls_private_key.pfc_ecs_key.public_key_openssh
}

# Write the private key to a local file
resource "local_file" "private_key" {
  content  = tls_private_key.pfc_ecs_key.private_key_pem
  filename = "${path.module}/pfc_ecs_private_key.pem"
}

# Write the public key to a local file
resource "local_file" "public_key" {
  content  = tls_private_key.pfc_ecs_key.public_key_openssh
  filename = "${path.module}/pfc_ecs_public_key.pub"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

# Launch template for all EC2 instances in ECS cluster

resource "aws_launch_template" "ecs-launch-template" {
  name     = "${var.environment}-${var.project}_ec2launchtemplate"
  image_id = data.aws_ami.amazon_linux_2.id
  # image_id               = "ami-07adf0ef1a2222084"
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.pfc_ecs_key.key_name
  user_data              = filebase64("${path.module}/user_data.sh")
  vpc_security_group_ids = [aws_security_group.ec2.id] ## Security group for EC2 instances

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_role_profile.arn
  }

  monitoring {
    enabled = true
  }
  depends_on = [aws_ecs_cluster.pfc-cluster]
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}



data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")

  vars = {
    ecs_cluster_name = aws_ecs_cluster.pfc-cluster.name
    ssh_public_key   = aws_key_pair.pfc_ecs_key.public_key
  }
  depends_on = [aws_ecs_cluster.pfc-cluster]
}

# IAM
# ------------------------------------------------------------------------------

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment}-${var.project}-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}


# Attach the AmazonECSTaskExecutionRolePolicy to the ECS Execution Role
resource "aws_iam_policy_attachment" "ecs_execution_role_attachment" {
  name       = "ecs_execution_role_attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  roles      = [aws_iam_role.ecs_execution_role.name]
}



# Creates IAM Role which is assumed by the Container Instances
resource "aws_iam_role" "ec2_instance_role" {
  name               = "${var.environment}-${var.project}-EC2InstanceRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_instance_role_profile" {
  name = "${var.environment}-${var.project}-EC2-InstanceRoleProfile"
  role = aws_iam_role.ec2_instance_role.id
}

data "aws_iam_policy_document" "ec2_instance_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}


resource "aws_iam_role" "ecs_task_iam_role" {
  name               = "${var.project}_ECS_TaskIAMRole_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}

data "aws_iam_policy_document" "task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Additional permissions for ecs tasks
data "aws_iam_policy_document" "ecs_task_additional_permissions" {
  statement {
    actions = [
      "elasticache:*",
      "rds:*",
      "rds-db:*",
      "rds-db:connect",
      "s3:*",
      "ec2:*",
      "elasticfilesystem:*"
    ]

    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_additional_permissions" {
  name        = "${var.project}_ECS_AdditionalPermissions_${var.environment}"
  description = "IAM policy with additional permissions for ECS cluster"

  policy = data.aws_iam_policy_document.ecs_task_additional_permissions.json
}

resource "aws_iam_role_policy_attachment" "ecs_additional_permissions" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_additional_permissions.arn
}


resource "aws_iam_role_policy_attachment" "ecs_task_additional_permissions" {
  role       = aws_iam_role.ecs_task_iam_role.name
  policy_arn = aws_iam_policy.ecs_additional_permissions.arn
}

resource "aws_iam_role_policy_attachment" "ec2_additional_permissions" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ecs_additional_permissions.arn
}

# ECS task and services
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "django_task" {
  family                   = "django-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_iam_role.arn

  container_definitions = jsonencode([{
    name  = "django",
    image = "${var.django_ecr_url}:latest",
    portMappings = [{
      containerPort = var.django_port
    }],
    essential = true,
    command   = ["/start"],
    cpu       = 512,
    memory    = 1024,


    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group"         = "${var.django_log_group_name}",
        "awslogs-region"        = "${var.aws_region}",
        "awslogs-stream-prefix" = "pfc-ecs"
      }
    },

    environmentFiles = [
      {
        type  = "s3",
        value = "arn:aws:s3:::${aws_s3_bucket.backend_secrets.id}/secrets/production-pfc-secrets.env"
      }
    ],
    environment = [
      { name = "REDIS_URL", value = var.elasticache_address }
    ],
    },
    ## CELERY WORKER CONTIANER
    {
      name      = "celeryworker",
      image     = "${var.django_ecr_url}:latest",
      essential = true,
      command   = ["/start-celeryworker"],
      memory    = 512,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "${var.celery_log_group_name}",
          "awslogs-region"        = "${var.aws_region}",
          "awslogs-stream-prefix" = "pfc-ecs"
        }
      },
      environmentFiles = [
        {
          type  = "s3",
          value = "arn:aws:s3:::${aws_s3_bucket.backend_secrets.id}/secrets/production-pfc-secrets.env"
        }
      ],
      environment = [
        { name = "REDIS_HOST", value = var.elasticache_address }
      ]
    },
    ## CELERY BEAT CONTAINER
    {
      name      = "celerybeat",
      image     = "${var.django_ecr_url}:latest",
      essential = true,
      command   = ["/start-celerybeat"],
      memory    = 256,
      # logConfiguration = {
      #   logDriver = "awslogs",
      #   options = {
      #     "awslogs-group"         = "${aws_cloudwatch_log_group.django_log_group.name}",
      #     "awslogs-region"        = "${var.aws_region}",
      #     "awslogs-stream-prefix" = "ecs"
      #   }
      # },
      environmentFiles = [
        {
          type  = "s3",
          value = "arn:aws:s3:::${aws_s3_bucket.backend_secrets.id}/secrets/production-pfc-secrets.env"
        }
      ],
      environment = [
        { name = "REDIS_HOST", value = var.elasticache_address }
      ]
    },
  ])
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# DJango Service
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "django_service" {
  name            = "${var.environment}-${var.project}-django-service"
  cluster         = aws_ecs_cluster.pfc-cluster.id
  task_definition = aws_ecs_task_definition.django_task.arn
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.public_subnets_id
    security_groups = [aws_security_group.pfc-cluster-sg.id]
    #assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.django_target_group_arn
    container_name   = "django"
    container_port   = var.django_port
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  desired_count                     = 2
  health_check_grace_period_seconds = 60
  depends_on                        = [aws_ecs_task_definition.django_task]
}
