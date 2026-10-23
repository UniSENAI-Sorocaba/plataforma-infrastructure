# INF-007.2: descomente quando modules/load-balancer estiver implementado (depende de network).

# module "load_balancer" {
#   source = "../../modules/load-balancer"
#
#   environment       = local.environment
#   vpc_id            = module.network.vpc_id
#   public_subnet_ids = module.network.public_subnet_ids
#   security_group_id = module.network.alb_security_group_id
# }
#
# output "alb_dns_name" {
#   value = module.load_balancer.alb_dns_name
# }
