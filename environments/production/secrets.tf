module "secrets" {
  source = "../../modules/secrets"

  environment             = local.environment
  secret_names            = ["backend/jwt-signing-key"]
  recovery_window_in_days = 30
}
