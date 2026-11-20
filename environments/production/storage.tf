module "storage" {
  source = "../../modules/storage"

  environment = local.environment
  kms_key_arn = module.secrets.kms_key_arn
}

output "storage_bucket_name" {
  value = module.storage.bucket_name
}
