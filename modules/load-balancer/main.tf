# Módulo load-balancer (porta de entrada) | Card: INF-007.2 (pai: INF-007)
#
# Criar:
#   - aws_lb.this tipo application, nas subnets públicas, drop_invalid_header_fields = true,
#     deletion_protection e idle_timeout conforme as variáveis.
#   - Se certificate_arn != null:
#       listener 443 HTTPS (ssl_policy ELBSecurityPolicy-TLS13-1-2-2021-06) e
#       listener 80 que só redireciona para 443.
#     Senão: listener 80 HTTP.
#   - Ação padrão do listener principal: fixed-response 404. Cada ecs-service cria a própria
#     regra (path) e o próprio target group; este módulo NÃO conhece backend nem frontend.
#
# Fora de escopo agora: access logs em S3, WAF e a restrição por cabeçalho secreto do
# CloudFront (INF-011).
