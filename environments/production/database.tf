variable "database_password" {
  description = "Senha inicial do PostgreSQL na EC2. Forneça por TF_VAR_database_password no CI."
  type        = string
  sensitive   = true
}

module "database" {
  source = "../../modules/postgres-ec2"

  environment         = local.environment
  vpc_id              = module.network.vpc_id
  subnet_id           = module.network.private_subnet_ids[0]
  security_group_id   = module.network.db_security_group_id
  kms_key_arn         = module.secrets.kms_key_arn
  database_password   = var.database_password
  deletion_protection = true
}
