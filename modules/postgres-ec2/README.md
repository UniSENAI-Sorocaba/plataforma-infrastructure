# Módulo `postgres-ec2`

Executa PostgreSQL 16 em uma EC2 Graviton privada, com volume EBS gp3 separado,
segredo no Secrets Manager, acesso administrativo pelo SSM e dump diário
comprimido em bucket S3 privado.

## Limites e responsabilidade operacional

Este módulo é a variante de menor custo para o ambiente acadêmico. Ele não
oferece failover automático como RDS Multi-AZ. O backup diário para S3 e o
snapshot do EBS devem ser testados regularmente com restore.

`database_password` é sensível e deve ser fornecida por `TF_VAR_database_password`
no CI. Nunca coloque a senha em `.tfvars` versionado. O state deve usar backend
S3 cifrado e restrito.

## Rede

A EC2 fica em subnet privada. O Security Group do banco aceita TCP/5432 somente
do Security Group das tasks ECS. A instância não recebe IP público; o SSM e o
download inicial da imagem PostgreSQL dependem da saída NAT da VPC.
