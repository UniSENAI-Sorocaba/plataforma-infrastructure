# INF-007.3: descomente junto com o development.
# O digest vem do CI (INF-009), nunca de uma tag mutável.

# variable "backend_image" {
#   description = "Imagem do backend por digest: <repo>@sha256:<digest>."
#   type        = string
# }
#
# module "backend" {
#   source = "../../modules/ecs-service"
#
#   environment            = local.environment
#   name                   = "backend"
#   image                  = var.backend_image
#   container_port         = 8080
#   cluster_arn            = module.ecs_cluster.cluster_arn
#   vpc_id                 = module.network.vpc_id
#   subnet_ids             = module.network.private_subnet_ids
#   security_group_id      = module.network.app_security_group_id
#   listener_arn           = module.load_balancer.listener_arn
#   listener_rule_priority = 10
#   path_patterns          = ["/api/*"]
#   health_check_path      = "/actuator/health"
#   kms_key_arn            = module.secrets.kms_key_arn
#
#   environment_variables = {
#     DB_HOST   = module.database.endpoint
#     DB_PORT   = tostring(module.database.port)
#     S3_BUCKET = module.storage.bucket_name
#   }
#
#   secret_arns = {
#     JWT_SIGNING_KEY = module.secrets.secret_arns["backend/jwt-signing-key"]
#   }
# }
