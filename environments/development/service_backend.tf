# INF-007.3: descomente quando modules/ecs-service estiver implementado
# (depende de network, secrets, database, storage, ecs_cluster e load_balancer).
# Imagem pública de teste: a imagem real do backend entra pelo CI (INF-009).

# module "backend" {
#   source = "../../modules/ecs-service"
#
#   environment            = local.environment
#   name                   = "backend"
#   image                  = "nginxinc/nginx-unprivileged:1.27-alpine"
#   require_image_digest   = false
#   container_port         = 8080
#   cluster_arn            = module.ecs_cluster.cluster_arn
#   vpc_id                 = module.network.vpc_id
#   subnet_ids             = module.network.private_subnet_ids
#   security_group_id      = module.network.app_security_group_id
#   listener_arn           = module.load_balancer.listener_arn
#   listener_rule_priority = 10
#   path_patterns          = ["/api/*"]
#   health_check_path      = "/"
#   kms_key_arn            = module.secrets.kms_key_arn
#
#   environment_variables = {
#     DB_HOST   = module.database.endpoint
#     DB_PORT   = tostring(module.database.port)
#     S3_BUCKET = module.storage.bucket_name
#   }
#
#   secret_arns = {
#     DB_MASTER_SECRET = module.database.master_secret_arn
#     JWT_SIGNING_KEY  = module.secrets.secret_arns["backend/jwt-signing-key"]
#   }
# }
