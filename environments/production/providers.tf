# Production: único ambiente na AWS (ADR-012). Só roda no CI, com role assumida via
# OIDC (INF-004). Ninguém aplica produção da própria máquina.
provider "aws" {
  region = "us-east-1"

  # INF-001: preencher com o ID da conta de produção quando ela for definida.
  # Impede aplicar este root na conta errada.
  # allowed_account_ids = ["000000000000"]

  default_tags {
    tags = local.tags
  }
}
