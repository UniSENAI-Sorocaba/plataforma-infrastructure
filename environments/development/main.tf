# Root do ambiente development. Cada módulo tem o próprio arquivo (network.tf,
# database.tf, ...). Quem implementa o módulo descomenta o bloco correspondente aqui
# e em environments/production. Mapa e ordem: docs/04-mapa-dos-modulos.md

locals {
  environment = "development"

  tags = {
    Project     = "plataforma-digital"
    Environment = local.environment
    ManagedBy   = "terraform"
    Squad       = "cloud-devops"
  }
}
