# Módulo ecs-cluster | Card: INF-007.1 (pai: INF-007)
#
# Criar:
#   - aws_ecs_cluster.this "plataforma-<ambiente>" com containerInsights conforme a variável.
#   - aws_ecs_cluster_capacity_providers com FARGATE (base 1) e FARGATE_SPOT (opcional, peso 0).
#
# O cluster é só o "agrupador"; quem roda container é o módulo ecs-service.
