provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

variables {
  repository_names = {
    infra    = "plataforma-infrastructure"
    backend  = "plataforma-backend"
    frontend = "plataforma-frontend"
    release  = "plataforma-release"
  }
  repository_ids = {
    infra    = "100000001"
    backend  = "100000002"
    frontend = "100000003"
    release  = "100000004"
  }
  backend_ecr_repository_arn  = "arn:aws:ecr:us-east-1:000000000000:repository/plataforma-backend"
  frontend_ecr_repository_arn = "arn:aws:ecr:us-east-1:000000000000:repository/plataforma-frontend"
  state_bucket_name           = "fixture-terraform-state"
  state_key                   = "plataforma/production/terraform.tfstate"
}

run "creates_oidc_provider_and_five_roles" {
  assert {
    condition     = length(aws_iam_role.this) == 5
    error_message = "O módulo deve criar as cinco roles planejadas."
  }

  assert {
    condition     = aws_iam_openid_connect_provider.this.url == "https://token.actions.githubusercontent.com" && contains(aws_iam_openid_connect_provider.this.client_id_list, "sts.amazonaws.com")
    error_message = "O provedor OIDC deve usar o emissor e audience oficiais do GitHub Actions."
  }

  assert {
    condition     = alltrue([for role in aws_iam_role.this : role.path == "/github-actions/"])
    error_message = "Todas as roles devem usar o path /github-actions/."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["infra-plan"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:UniSENAI-Sorocaba@321832374/plataforma-infrastructure@100000001:pull_request"
    error_message = "A trust de plan deve restringir o sub ao repositório infra em pull_request."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["infra-apply"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:UniSENAI-Sorocaba@321832374/plataforma-infrastructure@100000001:ref:refs/heads/main"
    error_message = "A trust de apply deve restringir o sub ao repositório infra na branch main."
  }

  assert {
    condition = alltrue([
      for role_key, subject in {
        backend-publish  = "repo:UniSENAI-Sorocaba@321832374/plataforma-backend@100000002:ref:refs/heads/main"
        frontend-publish = "repo:UniSENAI-Sorocaba@321832374/plataforma-frontend@100000003:ref:refs/heads/main"
        release-deploy   = "repo:UniSENAI-Sorocaba@321832374/plataforma-release@100000004:ref:refs/heads/main"
      } :
      jsondecode(aws_iam_role.this[role_key].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com" &&
      jsondecode(aws_iam_role.this[role_key].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == subject
    ])
    error_message = "As trusts de publish e release devem restringir audience, repositório e branch."
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.publish["backend"].policy).Statement[1].Resource == "arn:aws:ecr:us-east-1:000000000000:repository/plataforma-backend" && jsondecode(aws_iam_role_policy.publish["frontend"].policy).Statement[1].Resource == "arn:aws:ecr:us-east-1:000000000000:repository/plataforma-frontend"
    error_message = "Cada role de publicação deve acessar somente o ECR do seu aplicativo."
  }

  assert {
    condition     = !contains(data.aws_iam_policy_document.infra_plan_read.statement[0].actions, "secretsmanager:GetSecretValue")
    error_message = "A role infra-plan não pode ler valores de segredos."
  }

  assert {
    condition = alltrue([
      for role_policy in [aws_iam_role_policy.infra_plan_read.policy, aws_iam_role_policy.infra_plan_state.policy, aws_iam_role_policy.publish["backend"].policy, aws_iam_role_policy.publish["frontend"].policy] :
      alltrue([for statement in jsondecode(role_policy).Statement : !contains(flatten([statement.Action]), "*:*")])
    ])
    error_message = "Nenhuma policy deve conceder a ação global *:*."
  }
}

run "rejects_non_numeric_repository_ids" {
  command = plan

  variables {
    repository_ids = {
      infra    = "100000001"
      backend  = "backend-id"
      frontend = "100000003"
      release  = "100000004"
    }
  }

  expect_failures = [var.repository_ids]
}

run "rejects_invalid_repository_name" {
  command = plan

  variables {
    repository_names = {
      infra    = "plataforma-*"
      backend  = "plataforma-backend"
      frontend = "plataforma-frontend"
      release  = "plataforma-release"
    }
  }

  expect_failures = [var.repository_names]
}
