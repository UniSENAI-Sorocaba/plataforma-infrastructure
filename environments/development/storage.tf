# INF-010.1: descomente quando modules/storage estiver implementado (depende de secrets).

# module "storage" {
#   source = "../../modules/storage"
#
#   environment = local.environment
#   kms_key_arn = module.secrets.kms_key_arn
# }
