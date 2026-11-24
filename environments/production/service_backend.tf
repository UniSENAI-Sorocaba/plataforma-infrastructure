variable "backend_image" {
  description = "Imagem do backend por digest: <repo>@sha256:<digest>."
  type        = string
}

module "backend" {
  source = "../../modules/ecs-service"

  environment              = local.environment
  permissions_boundary_arn = var.workload_permissions_boundary_arn
  name                     = "backend"
  image                    = var.backend_image
  container_port           = 8080
  cluster_arn              = module.ecs_cluster.cluster_arn
  vpc_id                   = module.network.vpc_id
  subnet_ids               = module.network.private_subnet_ids
  security_group_id        = module.network.app_security_group_id
  listener_arn             = module.load_balancer.listener_arn
  listener_rule_priority   = 10
  path_patterns            = ["/api/*"]
  health_check_path        = "/actuator/health"
  kms_key_arn              = module.secrets.kms_key_arn

  environment_variables = {
    SPRING_DATASOURCE_URL                     = "jdbc:postgresql://${module.database.endpoint}:${module.database.port}/plataforma"
    SPRING_DATASOURCE_USERNAME                = "plataforma_admin"
    SPRING_MAIL_HOST                          = "disabled"
    SPRING_MAIL_PORT                          = "25"
    SECURITY_JWT_ENABLED                      = "true"
    SECURITY_JWT_ISSUER                       = "https://${var.public_domain}"
    SECURITY_JWT_AUDIENCE                     = "plataforma-api"
    SECURITY_PASSWORD_RECOVERY_DELIVERY       = "disabled"
    SECURITY_PASSWORD_RECOVERY_FROM           = "no-reply@${var.public_domain}"
    SECURITY_PASSWORD_RECOVERY_RESET_BASE_URL = "https://${var.public_domain}/login"
    PLATFORM_STORAGE_ROOT                     = "/tmp"
    S3_BUCKET                                 = module.storage.bucket_name
  }

  secret_arns = {
    JWT_SIGNING_KEY            = module.secrets.secret_arns["backend/jwt-signing-key"]
    SPRING_DATASOURCE_PASSWORD = "${module.database.secret_arn}:password::"
  }
}
