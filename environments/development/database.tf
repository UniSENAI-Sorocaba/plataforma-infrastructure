# INF-005.1: descomente quando modules/database estiver implementado
# (depende de network e secrets já descomentados).

# module "database" {
#   source = "../../modules/database"
#
#   environment                 = local.environment
#   multi_az                    = false
#   deletion_protection         = false
#   manage_master_user_password = false # o MiniStack não suporta; usa password_wo
#   subnet_ids                  = module.network.private_subnet_ids
#   security_group_id           = module.network.db_security_group_id
#   kms_key_arn                 = module.secrets.kms_key_arn
# }
#
# output "database_endpoint" {
#   value = module.database.endpoint
# }
