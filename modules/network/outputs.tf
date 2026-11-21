output "vpc_id" {
  description = "ID da VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas (ALB e NAT)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas (ECS e RDS)."
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "SG do ALB."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "SG das tasks ECS: entrada só do SG alb, nas app_ports."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "SG do RDS: entrada 5432 só do SG app."
  value       = aws_security_group.db.id
}
