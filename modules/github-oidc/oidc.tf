resource "aws_iam_openid_connect_provider" "this" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

locals {
  required_roles = {
    infra-plan = {
      name       = "gha-infra-plan"
      repository = "infra"
      context    = "pull_request"
      purpose    = "Read infrastructure state and inspect infrastructure in pull requests."
    }
    infra-apply = {
      name       = "gha-infra-apply"
      repository = "infra"
      context    = var.use_github_environments ? "environment:production" : "ref:refs/heads/main"
      purpose    = "Apply infrastructure changes from the main branch."
    }
    backend-publish = {
      name       = "gha-backend-publish"
      repository = "backend"
      context    = var.use_github_environments ? "environment:production" : "ref:refs/heads/main"
      purpose    = "Publish backend images to the backend ECR repository."
    }
    frontend-publish = {
      name       = "gha-frontend-publish"
      repository = "frontend"
      context    = var.use_github_environments ? "environment:production" : "ref:refs/heads/main"
      purpose    = "Publish frontend images to the frontend ECR repository."
    }
  }

  release_role = var.release_repository_id == null ? {} : {
    release-deploy = {
      name       = "gha-release-deploy"
      repository = "release"
      context    = var.use_github_environments ? "environment:production" : "ref:refs/heads/main"
      purpose    = "Deploy platform applications from the release repository."
    }
  }

  roles = merge(local.required_roles, local.release_role)

  repository_names = merge(var.repository_names, {
    release = "plataforma-release"
  })
  repository_ids = merge(var.repository_ids, var.release_repository_id == null ? {} : {
    release = var.release_repository_id
  })

  trust_subjects = {
    for role_key, role in local.roles :
    role_key => "repo:UniSENAI-Sorocaba@321832374/${local.repository_names[role.repository]}@${local.repository_ids[role.repository]}:${role.context}"
  }
}

data "aws_iam_policy_document" "trust" {
  for_each = local.roles

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.trust_subjects[each.key]]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = local.roles

  name                 = each.value.name
  path                 = "/github-actions/"
  description          = each.value.purpose
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = 3600
}
