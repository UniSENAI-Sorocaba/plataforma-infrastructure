data "aws_region" "current" {}

data "aws_iam_policy_document" "tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/plataforma-${var.name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_iam_role" "execution" {
  name               = "plataforma-${var.name}-${var.environment}-execution"
  assume_role_policy = data.aws_iam_policy_document.tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "secrets" {
  count = length(var.secret_arns) == 0 ? 0 : 1
  name  = "read-declared-secrets"
  role  = aws_iam_role.execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = values(var.secret_arns)
      }
      ], var.kms_key_arn == null ? [] : [{
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [var.kms_key_arn]
    }])
  })
}

resource "aws_iam_role" "task" {
  name               = "plataforma-${var.name}-${var.environment}-task"
  assume_role_policy = data.aws_iam_policy_document.tasks_assume.json
}

locals {
  environment = [for key, value in var.environment_variables : {
    name  = key
    value = value
  }]
  secrets = [for key, value in var.secret_arns : {
    name      = key
    valueFrom = value
  }]
}

resource "aws_ecs_task_definition" "this" {
  family                   = "plataforma-${var.name}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([{
    name                   = var.name
    image                  = var.image
    essential              = true
    user                   = "10001"
    readonlyRootFilesystem = true
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]
    environment = local.environment
    secrets     = local.secrets
    mountPoints = [{
      sourceVolume  = "tmp"
      containerPath = "/tmp"
      readOnly      = false
    }]
    linuxParameters = {
      capabilities = { drop = ["ALL"] }
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = var.name
      }
    }
  }])
}

resource "aws_lb_target_group" "this" {
  name                 = "plataforma-${var.name}-${var.environment}"
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 15

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = var.path_patterns
    }
  }
}

resource "aws_ecs_service" "this" {
  name            = "plataforma-${var.name}-${var.environment}"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  enable_execute_command = false

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener_rule.this]
}
