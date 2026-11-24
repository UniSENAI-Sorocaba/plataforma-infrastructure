variable "frontend_image" {
  description = "Imagem do frontend por digest: <repo>@sha256:<digest>."
  type        = string
}

module "frontend" {
  source = "../../modules/ecs-service"

  environment            = local.environment
  name                   = "frontend"
  image                  = var.frontend_image
  container_port         = 3000
  cluster_arn            = module.ecs_cluster.cluster_arn
  vpc_id                 = module.network.vpc_id
  subnet_ids             = module.network.private_subnet_ids
  security_group_id      = module.network.app_security_group_id
  listener_arn           = module.load_balancer.listener_arn
  listener_rule_priority = 100
  path_patterns          = ["/*"]
  health_check_path      = "/"
  kms_key_arn            = module.secrets.kms_key_arn

  environment_variables = {
    BACKEND_URL          = "https://${var.public_domain}"
    NEXT_PUBLIC_SITE_URL = "https://${var.public_domain}"
  }
}
