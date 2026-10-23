# Módulo storage (S3 de uploads) | Card: INF-010.1 (pai: INF-010)
#
# Criar:
#   - aws_s3_bucket.this "plataforma-uploads-<ambiente>" (force_destroy só em development).
#   - Public access block com os 4 bloqueios ligados.
#   - Ownership controls BucketOwnerEnforced (sem ACLs).
#   - Versionamento ligado.
#   - SSE-KMS com var.kms_key_arn e bucket_key_enabled = true.
#   - Bucket policy negando qualquer acesso sem TLS (aws:SecureTransport = false).
#   - Lifecycle: expira versões antigas e uploads multipart incompletos.
#   - CORS só se cors_allowed_origins não estiver vazio (PUT/GET).
#
# Referência: lab-terraform-local/modules/storage.
