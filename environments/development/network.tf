# INF-002.1: descomente quando modules/network estiver implementado.

# module "network" {
#   source = "../../modules/network"
#
#   environment       = local.environment
#   vpc_cidr          = "10.10.0.0/16"
#   enable_nat        = false # o emulador não tem rede real
#   alb_ingress_cidrs = ["0.0.0.0/0"]
# }
#
# output "vpc_id" {
#   value = module.network.vpc_id
# }
