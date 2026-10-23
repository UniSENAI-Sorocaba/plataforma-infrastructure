# Módulo network | Card: INF-002.1 (pai: INF-002)
#
# Criar:
#   - aws_vpc.this com DNS habilitado (enable_dns_support e enable_dns_hostnames).
#   - az_count subnets públicas e az_count privadas, distribuídas por zona (cidrsubnet).
#   - Internet Gateway e route tables (pública com rota 0.0.0.0/0 para o IGW).
#   - SGs encadeados: alb (443/80) -> app (app_ports, só do SG alb) -> db (5432, só do SG app).
#     Use aws_vpc_security_group_ingress_rule / egress_rule (um recurso por regra).
#   - Se enable_nat: fck-nat em ASG de 1 instância (IMDSv2, SSM, sem SSH) + rota privada.
#   - Se enable_flow_logs: Flow Logs só de REJECT para CloudWatch Logs.
#   - Bloquear a default security group da VPC (aws_default_security_group sem regras).
#
# Referência pronta para estudar: lab-terraform-local/modules/network (material de apoio).
