resource "aws_db_subnet_group" "this" {
  name        = "plataforma-db-${var.environment}"
  description = "Private database subnet group for ${var.environment}"
  subnet_ids  = var.subnet_ids
  tags        = { Name = "plataforma-db-${var.environment}" }
}

resource "aws_db_parameter_group" "this" {
  name        = "plataforma-db-postgres16-${var.environment}"
  description = "PostgreSQL 16 parameter group for ${var.environment}"
  family      = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_secretsmanager_secret" "master" {
  count                   = var.manage_master_user_password ? 0 : 1
  name                    = "plataforma/${var.environment}/database-master"
  description             = "Credencial do banco da Plataforma Digital"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.environment == "development" ? 0 : 30
}

resource "aws_db_instance" "managed" {
  count                       = var.manage_master_user_password ? 1 : 0
  identifier                  = "plataforma-${var.environment}"
  engine                      = "postgres"
  engine_version              = var.postgres_major_version
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.max_allocated_storage
  storage_type                = "gp3"
  storage_encrypted           = true
  kms_key_id                  = var.kms_key_arn
  db_name                     = "plataforma"
  username                    = "plataforma_admin"
  manage_master_user_password = true
  port                        = 5432
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [var.security_group_id]
  parameter_group_name        = aws_db_parameter_group.this.name
  publicly_accessible         = false
  multi_az                    = var.multi_az
  deletion_protection         = var.deletion_protection
  backup_retention_period     = var.backup_retention_days
  copy_tags_to_snapshot       = true
  auto_minor_version_upgrade  = true
  skip_final_snapshot         = false
  final_snapshot_identifier   = "plataforma-${var.environment}-final"
  apply_immediately           = false
  tags                        = { Name = "plataforma-${var.environment}" }
}

resource "aws_db_instance" "local" {
  count                      = var.manage_master_user_password ? 0 : 1
  identifier                 = "plataforma-${var.environment}"
  engine                     = "postgres"
  engine_version             = var.postgres_major_version
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.max_allocated_storage
  storage_type               = "gp3"
  storage_encrypted          = true
  kms_key_id                 = var.kms_key_arn
  db_name                    = "plataforma"
  username                   = "plataforma_admin"
  password_wo                = "local-development-only"
  password_wo_version        = 1
  port                       = 5432
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [var.security_group_id]
  parameter_group_name       = aws_db_parameter_group.this.name
  publicly_accessible        = false
  multi_az                   = var.multi_az
  deletion_protection        = var.deletion_protection
  backup_retention_period    = var.backup_retention_days
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  skip_final_snapshot        = true
  apply_immediately          = true
  tags                       = { Name = "plataforma-${var.environment}" }
}
