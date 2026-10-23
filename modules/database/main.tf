# Módulo database | Card: INF-005.1 (pai: INF-005)
#
# Criar:
#   - aws_db_subnet_group só com subnets privadas.
#   - aws_db_parameter_group família postgres16 com rds.force_ssl = 1.
#   - aws_db_instance.this: engine_version = var.postgres_major_version, gp3, storage_encrypted
#     com kms_key_id, publicly_accessible = false, multi_az, deletion_protection,
#     copy_tags_to_snapshot, auto_minor_version_upgrade, final_snapshot_identifier
#     (skip_final_snapshot só em development).
#   - Senha do admin:
#       manage_master_user_password = true  -> AWS gera e guarda no Secrets Manager (production);
#       manage_master_user_password = false -> ephemeral "random_password" + password_wo e um
#                                              aws_secretsmanager_secret com secret_string_wo.
#     Em nenhum dos dois casos a senha pode aparecer no state (terraform state pull).
#
# Limitação verificada no MiniStack 1.5.20: com manage_master_user_password = true o atributo
# master_user_secret volta vazio. Por isso development usa o caminho com password_wo.
# Referência: lab-terraform-local/modules/database (contém um WORKAROUND do emulador).
