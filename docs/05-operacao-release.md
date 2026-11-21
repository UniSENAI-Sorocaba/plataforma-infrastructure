# Operação de release: backup, rollback e observabilidade

## Antes do deploy

1. Confirmar `make check` e `make test-all` no MiniStack.
2. Confirmar imagem promovida por digest no ECR; nunca usar `latest` em produção.
3. Confirmar snapshot automatizado do RDS dentro da janela de retenção e registrar o identificador.
4. Confirmar alarmes do ALB/ECS/RDS e o endpoint `/actuator/health` do backend.

## Rollback

1. Pausar a promoção e preservar logs, digest atual e o novo.
2. Atualizar o serviço ECS para o último digest saudável e aguardar `deployment circuit breaker`.
3. Se houver migração incompatível, restaurar primeiro a instância RDS em uma instância temporária; nunca sobrescrever o banco de produção sem aprovação operacional.
4. Executar smoke test de login, catálogo, submissão de atividade e validação de certificado.

## Backup/restore

O restore deve ser ensaiado em instância temporária, com evidência de: snapshot usado, tempo de restauração, versão do schema, contagem de tabelas e smoke tests. A execução real depende de uma conta AWS de produção configurada; o MiniStack valida apenas a estrutura Terraform e não substitui o RDS.

## Observabilidade

Monitorar disponibilidade, latência p95, 5xx, saturação ECS, conexões RDS e erros de autenticação. Qualquer alerta deve conter serviço, região, horário UTC, digest e correlação da requisição.
