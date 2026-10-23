# INF-011: o runtime do frontend ainda depende do ADR-010. Se for ECS Fargate, este
# bloco reaproveita modules/ecs-service (Fase 2, depois do backend).

# module "frontend" {
#   source = "../../modules/ecs-service"
#
#   environment            = local.environment
#   name                   = "frontend"
#   image                  = "nginxinc/nginx-unprivileged:1.27-alpine"
#   require_image_digest   = false
#   container_port         = 8080
#   cluster_arn            = module.ecs_cluster.cluster_arn
#   vpc_id                 = module.network.vpc_id
#   subnet_ids             = module.network.private_subnet_ids
#   security_group_id      = module.network.app_security_group_id
#   listener_arn           = module.load_balancer.listener_arn
#   listener_rule_priority = 100
#   path_patterns          = ["/*"]
#   health_check_path      = "/"
# }
