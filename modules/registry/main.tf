# Módulo registry (ECR) | Card: INF-006.1 (pai: INF-006)
#
# Criar, para cada item de var.repositories (for_each):
#   - aws_ecr_repository com image_tag_mutability = "IMMUTABLE", scan on push e cifragem.
#   - aws_ecr_lifecycle_policy: expira imagens sem tag após 7 dias e mantém as últimas
#     keep_last_images com tag.
#
# Não inclui: policy de quem pode dar push (fica com as roles do OIDC, INF-004.1).
# Referência: lab-terraform-local/modules/registry.
