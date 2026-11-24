# Root do ambiente production. Mesmos módulos do development, com valores de produção.
# Aqui só dá para rodar make check (validate); plan/apply dependem da conta AWS (INF-001).

locals {
  environment = "production"

  tags = {
    Project     = "plataforma-digital"
    Environment = local.environment
    ManagedBy   = "terraform"
    Squad       = "cloud-devops"
  }
}

# Todos os valores abaixo devem ser fornecidos pelo CI/OIDC. Não versionar um
# terraform.tfvars com imagens, certificados ou senha do banco.
