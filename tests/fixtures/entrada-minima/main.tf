# Fixture: cluster ECS + ALB com listener HTTP, para testar o ecs-service antes do
# ecs-cluster e do load-balancer ficarem prontos. Mesmos nomes de output dos contratos.
# Atenção: o MiniStack leva cerca de 1 minuto para criar o ALB.
terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

resource "aws_ecs_cluster" "this" {
  name = "teste-fixture"
}

resource "aws_lb" "this" {
  name               = "teste-fixture"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "not found"
      status_code  = "404"
    }
  }
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}
