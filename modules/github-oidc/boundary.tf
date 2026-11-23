data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "workload_boundary" {
  statement {
    sid       = "AuthenticateToEcr"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PullPlatformImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/plataforma-*-production"]
  }

  statement {
    sid    = "WritePlatformLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/ecs/plataforma-*:*",
      "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/vpc/flow-logs/plataforma-*:*"
    ]
  }

  statement {
    sid       = "DescribePlatformLogGroups"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadPlatformSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:plataforma/production/*"]
  }

  statement {
    sid       = "DecryptPlatformSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:us-east-1:${data.aws_caller_identity.current.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.us-east-1.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:SecretARN"
      values   = ["arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:plataforma/production/*"]
    }
  }

  statement {
    sid    = "AccessPlatformUploads"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::plataforma-uploads-production/*"]
  }

  statement {
    sid       = "ListPlatformUploads"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::plataforma-uploads-production"]
  }

  statement {
    sid    = "UsePlatformUploadKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["arn:aws:kms:us-east-1:${data.aws_caller_identity.current.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.us-east-1.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["arn:aws:s3:::plataforma-uploads-production*"]
    }
  }

  statement {
    sid    = "DenyWorkloadIamPrivilegeChanges"
    effect = "Deny"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateAccessKey",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:CreateRole",
      "iam:CreateUser",
      "iam:DeleteRole",
      "iam:DeleteRolePermissionsBoundary",
      "iam:DeleteRolePolicy",
      "iam:DeleteUser",
      "iam:DetachRolePolicy",
      "iam:PassRole",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy",
      "iam:SetDefaultPolicyVersion",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateAccessKey"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "infra_plan_boundary" {
  source_policy_documents = [
    data.aws_iam_policy_document.infra_plan_read.json,
    data.aws_iam_policy_document.infra_plan_state.json
  ]
}

data "aws_iam_policy_document" "release_boundary" {
  statement {
    sid       = "DenyRolePassingUntilDeployPermissionsAreDefined"
    effect    = "Deny"
    actions   = ["iam:PassRole"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "infra_apply_boundary" {
  statement {
    sid    = "ManagePlatformServices"
    effect = "Allow"
    actions = [
      "ec2:*",
      "ecr:*",
      "ecs:*",
      "elasticloadbalancing:*",
      "logs:*",
      "rds:*"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  }

  statement {
    sid       = "ManagePlatformS3Buckets"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::plataforma-*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  }

  statement {
    sid    = "ReadTerraformStateBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning"
    ]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid       = "ListTerraformState"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = [var.state_key, "${var.state_key}.tflock"]
    }
  }

  statement {
    sid    = "ManageTerraformStateObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket_name}/${var.state_key}",
      "arn:aws:s3:::${var.state_bucket_name}/${var.state_key}.tflock"
    ]
  }

  statement {
    sid       = "CreatePlatformKmsKeys"
    effect    = "Allow"
    actions   = ["kms:CreateKey"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = ["plataforma-digital"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["production"]
    }
  }

  statement {
    sid    = "ManageTaggedPlatformKmsKeys"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["arn:aws:kms:us-east-1:${data.aws_caller_identity.current.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = ["plataforma-digital"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["production"]
    }
  }

  statement {
    sid    = "ManagePlatformKmsAliases"
    effect = "Allow"
    actions = [
      "kms:CreateAlias",
      "kms:UpdateAlias",
      "kms:DeleteAlias"
    ]
    resources = [
      "arn:aws:kms:us-east-1:${data.aws_caller_identity.current.account_id}:alias/plataforma-*",
      "arn:aws:kms:us-east-1:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  }

  statement {
    sid       = "ListKmsAliases"
    effect    = "Allow"
    actions   = ["kms:ListAliases"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  }

  statement {
    sid    = "CreatePlatformSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:CreateSecret"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }

    condition {
      test     = "StringLike"
      variable = "secretsmanager:Name"
      values   = ["plataforma/production/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = ["plataforma-digital"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["production"]
    }
  }

  statement {
    sid    = "ManagePlatformSecretMetadata"
    effect = "Allow"
    actions = [
      "secretsmanager:*"
    ]
    resources = ["arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:plataforma/production/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  }

  statement {
    sid    = "CreatePlatformRolesOnlyWithBoundary"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:PutRolePermissionsBoundary"
    ]
    resources = ["arn:aws:iam::*:role/plataforma-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.workload_boundary.arn]
    }
  }

  statement {
    sid    = "ManagePlatformRoles"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole"
    ]
    resources = ["arn:aws:iam::*:role/plataforma-*"]
  }

  statement {
    sid    = "PassPlatformRolesToTheirServices"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["arn:aws:iam::*:role/plataforma-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ecs-tasks.amazonaws.com",
        "vpc-flow-logs.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "ReadPlatformRoleConfiguration"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListRoles"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "ReadAttachedPolicyDocuments"
    effect    = "Allow"
    actions   = ["iam:GetPolicy", "iam:GetPolicyVersion"]
    resources = ["arn:aws:iam::*:policy/*"]
  }

  statement {
    sid    = "CreateServiceLinkedRolesForPlatformServices"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "ecs.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "rds.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "ProtectTerraformStateBucket"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPolicy"
    ]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid    = "ProtectGitHubActionsRoles"
    effect = "Deny"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePermissionsBoundary",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole"
    ]
    resources = ["arn:aws:iam::*:role/github-actions/*"]
  }

  statement {
    sid    = "ProtectGitHubOidcProvider"
    effect = "Deny"
    actions = [
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint"
    ]
    resources = [aws_iam_openid_connect_provider.this.arn]
  }

  statement {
    sid    = "ProtectWorkloadBoundary"
    effect = "Deny"
    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]
    resources = [aws_iam_policy.workload_boundary.arn]
  }
}

locals {
  github_actions_boundary_documents = {
    infra-plan       = data.aws_iam_policy_document.infra_plan_boundary.json
    infra-apply      = data.aws_iam_policy_document.infra_apply_boundary.json
    backend-publish  = data.aws_iam_policy_document.publish["backend"].json
    frontend-publish = data.aws_iam_policy_document.publish["frontend"].json
    release-deploy   = data.aws_iam_policy_document.release_boundary.json
  }
}

resource "aws_iam_policy" "github_actions_boundary" {
  for_each = local.roles

  name        = "${each.value.name}-permissions-boundary"
  description = "Permissions ceiling for ${each.value.name}."
  policy      = local.github_actions_boundary_documents[each.key]
}

resource "aws_iam_policy" "workload_boundary" {
  name        = "plataforma-workload-boundary"
  description = "Limite de permissões para roles de workload da Plataforma Digital."
  policy      = data.aws_iam_policy_document.workload_boundary.json
}
