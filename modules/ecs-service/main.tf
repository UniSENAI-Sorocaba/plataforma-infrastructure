# Módulo ecs-service (serviço Fargate genérico) | Card: INF-007.3 (pai: INF-007)
# O mesmo módulo roda o backend e, quando o ADR-010 fechar, o frontend.
#
# Criar:
#   - aws_cloudwatch_log_group "/ecs/plataforma-<name>-<ambiente>" com retenção e KMS.
#   - Execution role: AmazonECSTaskExecutionRolePolicy + secretsmanager:GetSecretValue SOMENTE
#     nos ARNs de var.secret_arns (+ kms:Decrypt na chave, se houver).
#   - Task role vazia (o root anexa o que a aplicação precisa, ex.: S3).
#   - aws_ecs_task_definition FARGATE, awsvpc, runtime_platform = var.cpu_architecture, com
#     container endurecido: user não root, readonlyRootFilesystem = true (volume efêmero para
#     /tmp), linuxParameters.capabilities.drop = ["ALL"], logConfiguration awslogs,
#     "secrets" a partir de var.secret_arns (nunca em "environment").
#   - aws_lb_target_group tipo ip, healthcheck em health_check_path, deregistration_delay curto.
#   - aws_lb_listener_rule no listener_arn com path_patterns e listener_rule_priority.
#   - aws_ecs_service: launch_type FARGATE, subnets privadas, assign_public_ip = false,
#     enable_execute_command = false, deployment_circuit_breaker { enable, rollback = true },
#     depends_on na listener rule.
#
# No MiniStack o serviço sobe um container real (docker ps mostra ministack-ecs-*).
