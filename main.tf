# Manages Terraform Remote State
module "backend" {
  source  = "./modules/backend"
  region  = var.aws_region
  project = var.project
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
}

module "acm" {
  source      = "./modules/acm"
  environment = var.environment
  project     = var.project
  domain_name = var.domain
}

module "alb" {
  source                    = "./modules/alb"
  environment               = var.environment
  public_subnets_id         = data.aws_subnets.public.ids
  vpc_id                    = var.vpc_id
  project                   = var.project
  aws_acm_load_balancer_arn = module.acm.aws_acm_load_balancer_arn
  ecs_security_group_id     = module.ecs.ecs_security_group
}

module "storage" {
  source               = "./modules/storage"
  environment          = var.environment
  project              = var.project
  vpc_id               = var.vpc_id
  subnet_ids           = data.aws_subnets.public.ids
  redis_instance_class = var.redis_instance_class
  redis_port           = var.redis_port
}

module "networking" {
  source            = "./modules/networking"
  environment       = var.environment
  project           = var.project
  vpc_id            = var.vpc_id
  public_subnets_id = data.aws_subnets.public.ids
}

module "ecs" {
  source                  = "./modules/ecs"
  environment             = var.environment
  project                 = var.project
  django_ecr_url          = module.storage.ecr_url
  elasticache_address     = module.storage.redis_address
  aws_region              = var.aws_region
  vpc_id                  = var.vpc_id
  public_subnets_id       = data.aws_subnets.public.ids
  private_subnet_ids      = module.networking.private_subnet_ids
  django_log_group_name   = module.cloudwatch.django_log_group_name
  django_target_group_arn = module.alb.django_target_group_arn
  celery_log_group_name   = module.cloudwatch.celery_log_group_name
}
