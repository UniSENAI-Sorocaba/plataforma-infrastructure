module "github_oidc" {
  source = "../../modules/github-oidc"

  repository_names            = var.repository_names
  repository_ids              = var.repository_ids
  backend_ecr_repository_arn  = var.backend_ecr_repository_arn
  frontend_ecr_repository_arn = var.frontend_ecr_repository_arn
  state_bucket_name           = var.state_bucket_name
  state_key                   = var.state_key
}
