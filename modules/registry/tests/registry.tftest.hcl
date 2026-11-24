# make test MOD=registry | Guia: docs/02-testar-no-ministack.md
# Endpoint vem de AWS_ENDPOINT_URL (o make test define). Credenciais falsas de propósito:
# sem o MiniStack, a chamada vai para a AWS real e falha, em vez de criar algo lá.
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

variables {
  environment = "development"
}

run "cria_repositorios" {
  assert {
    condition     = alltrue([for r in aws_ecr_repository.this : r.image_tag_mutability == "IMMUTABLE"])
    error_message = "Todos os repositórios devem ter image_tag_mutability = IMMUTABLE."
  }

  assert {
    condition     = alltrue([for r in aws_ecr_repository.this : r.image_scanning_configuration[0].scan_on_push == true])
    error_message = "Todos os repositórios devem ter scan_on_push habilitado."
  }

  assert {
    condition     = alltrue([for r in aws_ecr_repository.this : r.encryption_configuration[0].encryption_type == "AES256"])
    error_message = "Sem kms_key_arn, a cifragem padrão deve ser AES256."
  }

  assert {
    condition = (
      toset([for r in aws_ecr_repository.this : r.name]) == toset([
        "plataforma-backend-development",
        "plataforma-frontend-development",
      ]) &&
      alltrue([for k, r in aws_ecr_repository.this : r.name == "plataforma-${k}-development"])
    )
    error_message = "Nomes devem seguir o padrão plataforma-<repo>-<ambiente>."
  }

  assert {
    condition = (
      keys(aws_ecr_lifecycle_policy.this) == keys(aws_ecr_repository.this) &&
      alltrue([for k, p in aws_ecr_lifecycle_policy.this : p.repository == aws_ecr_repository.this[k].name])
    )
    error_message = "Cada repositório deve possuir uma lifecycle policy associada."
  }

  assert {
    condition = alltrue([
      for p in aws_ecr_lifecycle_policy.this : (
        length(jsondecode(p.policy).rules) == 2 &&
        anytrue([
          for rule in jsondecode(p.policy).rules : (
            rule.selection.tagStatus == "untagged" &&
            rule.selection.countType == "sinceImagePushed" &&
            rule.selection.countUnit == "days" &&
            rule.selection.countNumber == 7 &&
            rule.action.type == "expire"
          )
        ]) &&
        anytrue([
          for rule in jsondecode(p.policy).rules : (
            rule.selection.tagStatus == "tagged" &&
            rule.selection.countType == "imageCountMoreThan" &&
            rule.selection.countNumber == 20 &&
            rule.action.type == "expire"
          )
        ])
      )
    ])
    error_message = "Lifecycle policy deve expirar sem tag em 7 dias e manter as últimas keep_last_images com tag."
  }

  assert {
    condition = (
      toset(keys(output.repository_urls)) == toset(["backend", "frontend"]) &&
      toset(keys(output.repository_arns)) == toset(["backend", "frontend"]) &&
      alltrue([for k, u in output.repository_urls : endswith(u, "/plataforma-${k}-development")]) &&
      alltrue([for k, a in output.repository_arns : endswith(a, ":repository/plataforma-${k}-development")])
    )
    error_message = "Outputs repository_urls e repository_arns devem expor os repositórios criados."
  }
}

run "kms" {
  module {
    source = "../../tests/fixtures/kms-minima"
  }
}

run "cifra_com_kms" {
  variables {
    repositories     = ["backend"]
    kms_key_arn      = run.kms.kms_key_arn
    keep_last_images = 10
  }

  assert {
    condition = (
      aws_ecr_repository.this["backend"].encryption_configuration[0].encryption_type == "KMS" &&
      aws_ecr_repository.this["backend"].encryption_configuration[0].kms_key == run.kms.kms_key_arn
    )
    error_message = "Quando kms_key_arn é informada, o repositório deve usar cifragem KMS com a chave recebida."
  }

  assert {
    condition = anytrue([
      for rule in jsondecode(aws_ecr_lifecycle_policy.this["backend"].policy).rules : (
        rule.selection.tagStatus == "tagged" &&
        rule.selection.countNumber == 10
      )
    ])
    error_message = "Lifecycle policy deve respeitar keep_last_images customizado."
  }
}

run "protege_exclusao_em_production" {
  command = plan

  variables {
    environment = "production"
  }

  assert {
    condition     = alltrue([for r in aws_ecr_repository.this : r.force_delete == false])
    error_message = "Em production, force_delete deve ser false."
  }

  assert {
    condition     = alltrue([for k, r in aws_ecr_repository.this : r.name == "plataforma-${k}-production"])
    error_message = "Em production, o nome deve usar sufixo -production."
  }
}

run "recusa_ambiente_invalido" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [var.environment]
}
