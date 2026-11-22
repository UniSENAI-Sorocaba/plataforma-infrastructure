data "aws_iam_policy_document" "infra_plan_read" {
  statement {
    sid    = "ReadPlatformConfiguration"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:ListDistributions",
      "cloudfront:ListOriginAccessControls",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetMetricData",
      "cloudwatch:ListTagsForResource",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNatGateways",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcs",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:ListClusters",
      "ecs:ListServices",
      "ecs:ListTagsForResource",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListOpenIDConnectProviders",
      "iam:ListRolePolicies",
      "iam:ListRoles",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:ListAliases",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "rds:DescribeDBInstances",
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeEventSubscriptions",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "sns:GetTopicAttributes",
      "sns:ListTopics",
      "s3:GetBucketAcl",
      "s3:GetBucketCors",
      "s3:GetBucketLifecycleConfiguration",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "infra_plan_read" {
  name   = "platform-read-only"
  role   = aws_iam_role.this["infra-plan"].id
  policy = data.aws_iam_policy_document.infra_plan_read.json
}

data "aws_iam_policy_document" "infra_plan_state" {
  statement {
    sid       = "ReadStateBucketMetadata"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid       = "ListStateAndLockObjects"
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
    sid       = "ReadTerraformState"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/${var.state_key}"]
  }

  statement {
    sid    = "ManageTerraformPlanLock"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/${var.state_key}.tflock"]
  }
}

resource "aws_iam_role_policy" "infra_plan_state" {
  name   = "terraform-state-plan-lock"
  role   = aws_iam_role.this["infra-plan"].id
  policy = data.aws_iam_policy_document.infra_plan_state.json
}

locals {
  publish_roles = {
    backend = {
      role_key       = "backend-publish"
      repository_arn = var.backend_ecr_repository_arn
    }
    frontend = {
      role_key       = "frontend-publish"
      repository_arn = var.frontend_ecr_repository_arn
    }
  }
}

data "aws_iam_policy_document" "publish" {
  for_each = local.publish_roles

  statement {
    sid       = "AuthenticateToEcr"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PublishOnlyOwnImage"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [each.value.repository_arn]
  }
}

resource "aws_iam_role_policy" "publish" {
  for_each = local.publish_roles

  name   = "publish-own-image"
  role   = aws_iam_role.this[each.value.role_key].id
  policy = data.aws_iam_policy_document.publish[each.key].json
}
