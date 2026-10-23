# CONTRATO: estes nomes são usados por outros módulos e pelos roots.
# Troque cada `null` pela referência real (ex.: aws_vpc.this.id). Não renomeie.

output "vpc_id" {
  description = "ID da VPC."
  value       = null # TODO(INF-002.1)
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas (ALB e NAT)."
  value       = null # TODO(INF-002.1)
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas (ECS e RDS)."
  value       = null # TODO(INF-002.1)
}

output "alb_security_group_id" {
  description = "SG do ALB."
  value       = null # TODO(INF-002.1)
}

output "app_security_group_id" {
  description = "SG das tasks ECS: entrada só do SG alb, nas app_ports."
  value       = null # TODO(INF-002.1)
}

output "db_security_group_id" {
  description = "SG do RDS: entrada 5432 só do SG app."
  value       = null # TODO(INF-002.1)
}
