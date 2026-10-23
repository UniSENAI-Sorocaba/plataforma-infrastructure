# Módulo secrets | Card: INF-008.1 (pai: INF-008)
#
# Criar:
#   - aws_kms_key.this com rotação anual ligada + aws_kms_alias "alias/plataforma-<ambiente>".
#   - Key policy: administração pela conta; uso (Encrypt/Decrypt/GenerateDataKey) pelos serviços
#     que precisam (RDS, S3, Secrets Manager, CloudWatch Logs). Sem "kms:*" para Principal "*".
#   - Um aws_secretsmanager_secret por item de secret_names, cifrado com a chave acima.
#
# Este módulo cria só o "cofre". O VALOR de cada segredo nunca entra no código nem no state:
# em production ele é gravado fora do Terraform (CLI/console) ou com secret_string_wo
# (write-only, Terraform >= 1.11). Nenhum output pode expor valor de segredo.
