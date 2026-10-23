# Ambiente development: existe SÓ no MiniStack (ADR-012). Rode sempre pelo make,
# que define AWS_ENDPOINT_URL=http://localhost:4566.
# As credenciais falsas são proteção: sem o endpoint local, a chamada vai para a AWS
# real e falha, em vez de criar recursos na conta de alguém.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  default_tags {
    tags = local.tags
  }
}
