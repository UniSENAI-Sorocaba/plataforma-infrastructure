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
  }
  release_repository_id       = "100000004"
  use_github_environments     = false
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
    condition     = aws_iam_policy.workload_boundary.name == "plataforma-workload-boundary"
    error_message = "O módulo deve criar a permissions boundary com o nome contratado."
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
    condition     = jsondecode(aws_iam_role.this["infra-plan"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com" && jsondecode(aws_iam_role.this["infra-plan"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:UniSENAI-Sorocaba@321832374/plataforma-infrastructure@100000001:pull_request"
    error_message = "A trust de plan deve restringir o sub ao repositório infra em pull_request."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["infra-apply"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com" && jsondecode(aws_iam_role.this["infra-apply"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:UniSENAI-Sorocaba@321832374/plataforma-infrastructure@100000001:ref:refs/heads/main"
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
    condition = anytrue([
      for statement in jsondecode(data.aws_iam_policy_document.infra_apply_services.json).Statement :
      statement.Sid == "CreatePlatformRolesOnlyWithBoundary" &&
      statement.Condition.StringEquals["iam:PermissionsBoundary"] == aws_iam_policy.workload_boundary.arn
    ])
    error_message = "A criação e atribuição de permissions boundary em roles deve exigir a boundary da plataforma."
  }

  assert {
    condition = anytrue([
      for statement in jsondecode(data.aws_iam_policy_document.infra_apply_services.json).Statement :
      statement.Sid == "ManagePlatformKmsKeyDeletion" &&
      contains(flatten([statement.Action]), "kms:ScheduleKeyDeletion") &&
      statement.Condition.StringEquals["aws:ResourceTag/Project"] == "plataforma-digital" &&
      statement.Condition.StringEquals["aws:ResourceTag/Environment"] == "production"
    ])
    error_message = "A exclusão de chaves KMS deve ser limitada às chaves tagged da plataforma."
  }

  assert {
    condition = anytrue([
      for statement in jsondecode(data.aws_iam_policy_document.infra_apply_services.json).Statement :
      statement.Sid == "ProtectGitHubActionsRoles" &&
      statement.Effect == "Deny" &&
      statement.Resource == "arn:aws:iam::*:role/github-actions/*"
    ])
    error_message = "A role infra-apply deve negar alterações às roles GitHub Actions."
  }

  assert {
    condition = alltrue([
      anytrue([
        for statement in jsondecode(data.aws_iam_policy_document.infra_apply_services.json).Statement :
        statement.Sid == "ProtectGitHubOidcProvider" &&
        statement.Effect == "Deny" &&
        statement.Resource == aws_iam_openid_connect_provider.this.arn
      ]),
      anytrue([
        for statement in jsondecode(data.aws_iam_policy_document.infra_apply_services.json).Statement :
        statement.Sid == "ProtectWorkloadBoundary" &&
        statement.Effect == "Deny" &&
        statement.Resource == aws_iam_policy.workload_boundary.arn
      ])
    ])
    error_message = "A role infra-apply deve negar alterações ao provedor OIDC e à boundary."
  }

  assert {
    condition     = !contains(data.aws_iam_policy_document.infra_plan_read.statement[0].actions, "secretsmanager:GetSecretValue")
    error_message = "A role infra-plan não pode ler valores de segredos."
  }

  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_role_policy.infra_plan_state.policy).Statement :
      statement.Sid == "ManageTerraformPlanLock" ||
      !anytrue([
        for action in flatten([statement.Action]) :
        contains(["s3:PutObject", "s3:DeleteObject"], action)
      ])
      ]) && anytrue([
      for statement in jsondecode(aws_iam_role_policy.infra_plan_state.policy).Statement :
      statement.Sid == "ManageTerraformPlanLock" &&
      statement.Resource == "arn:aws:s3:::fixture-terraform-state/plataforma/production/terraform.tfstate.tflock" &&
      alltrue([
        for action in flatten([statement.Action]) :
        contains(["s3:DeleteObject", "s3:GetObject", "s3:PutObject"], action)
      ])
    ])
    error_message = "A role infra-plan só pode escrever e excluir o objeto de lock .tflock."
  }

  assert {
    condition = alltrue([
      for role_policy in [
        aws_iam_role_policy.infra_plan_read.policy,
        aws_iam_role_policy.infra_plan_state.policy,
        aws_iam_role_policy.publish["backend"].policy,
        aws_iam_role_policy.publish["frontend"].policy,
        data.aws_iam_policy_document.infra_apply_services.json,
        data.aws_iam_policy_document.workload_boundary.json
      ] :
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
    }
  }

  expect_failures = [var.repository_names]
}

run "release_role_is_optional" {
  command = plan

  variables {
    release_repository_id = null
  }

  assert {
    condition     = length(aws_iam_role.this) == 4 && !contains(keys(aws_iam_role.this), "release-deploy")
    error_message = "A role gha-release-deploy só deve existir quando release_repository_id for informado."
  }
}

run "uses_github_environment_subjects_when_enabled" {
  command = plan

  variables {
    use_github_environments = true
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["infra-apply"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:UniSENAI-Sorocaba@321832374/plataforma-infrastructure@100000001:environment:production"
    error_message = "Com GitHub Environments habilitado, a trust de apply deve exigir o environment production."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this["infra-plan"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:UniSENAI-Sorocaba@321832374/plataforma-infrastructure@100000001:pull_request"
    error_message = "Habilitar GitHub Environments não deve alterar o contexto pull_request de plan."
  }

  assert {
    condition = alltrue([
      for role_key, subject in {
        infra-apply      = "repo:UniSENAI-Sorocaba@321832374/plataforma-infrastructure@100000001:environment:production"
        backend-publish  = "repo:UniSENAI-Sorocaba@321832374/plataforma-backend@100000002:environment:production"
        frontend-publish = "repo:UniSENAI-Sorocaba@321832374/plataforma-frontend@100000003:environment:production"
        release-deploy   = "repo:UniSENAI-Sorocaba@321832374/plataforma-release@100000004:environment:production"
      } :
      jsondecode(aws_iam_role.this[role_key].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com" &&
      jsondecode(aws_iam_role.this[role_key].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == subject
    ])
    error_message = "As trusts de apply, publish e release devem exigir o subject imutável do Environment production."
  }
}

run "rejects_non_numeric_release_repository_id" {
  command = plan

  variables {
    release_repository_id = "release-id"
  }

  expect_failures = [var.release_repository_id]
}

run "rejects_wildcards_in_ecr_repository_arn" {
  command = plan

  variables {
    backend_ecr_repository_arn = "arn:aws:ecr:us-east-1:000000000000:repository/plataforma-*"
  }

  expect_failures = [var.backend_ecr_repository_arn]
}

run "rejects_wildcards_in_state_key" {
  command = plan

  variables {
    state_key = "plataforma/production/*"
  }

  expect_failures = [var.state_key]
}
