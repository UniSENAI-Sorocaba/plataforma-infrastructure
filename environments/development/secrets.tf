# INF-008.1: descomente quando modules/secrets estiver implementado.

# module "secrets" {
#   source = "../../modules/secrets"
#
#   environment                 = local.environment
#   secret_names                = ["backend/jwt-signing-key"]
#   recovery_window_in_days     = 0 # permite destroy/apply seguidos no laboratório
#   kms_deletion_window_in_days = 7
# }
