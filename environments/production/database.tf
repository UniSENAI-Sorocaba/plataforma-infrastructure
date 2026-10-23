# INF-005.1: descomente junto com o development.

# module "database" {
#   source = "../../modules/database"
#
#   environment         = local.environment
#   multi_az            = true # variante de custo P3
#   deletion_protection = true
#   subnet_ids          = module.network.private_subnet_ids
#   security_group_id   = module.network.db_security_group_id
#   kms_key_arn         = module.secrets.kms_key_arn
# }
