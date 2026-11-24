output "distribution_id" {
  description = "ID da distribuição CloudFront."
  value       = aws_cloudfront_distribution.this.id
}

output "domain_name" {
  description = "Domínio público da distribuição."
  value       = aws_cloudfront_distribution.this.domain_name
}
