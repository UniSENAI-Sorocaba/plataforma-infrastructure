module "registry" {
  source = "../../modules/registry"

  environment = local.environment
}

output "repository_urls" {
  value = module.registry.repository_urls
}
