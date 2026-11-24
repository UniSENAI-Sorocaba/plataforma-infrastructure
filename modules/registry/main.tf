# Módulo registry (ECR) | Card: INF-006.1 (pai: INF-006)
#
# Cria um repositório ECR por item de var.repositories com:
#   - image_tag_mutability = "IMMUTABLE" e scan_on_push = true;
#   - cifragem KMS (quando var.kms_key_arn é informada) ou AES256;
#   - lifecycle policy expirando imagens sem tag em 7 dias e mantendo as últimas
#     var.keep_last_images imagens com tag.

resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = "plataforma-${each.value}-${var.environment}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.environment == "development"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expira imagens sem tag apos 7 dias"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Mantem as ultimas ${var.keep_last_images} imagens com tag"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"]
          countType      = "imageCountMoreThan"
          countNumber    = var.keep_last_images
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
