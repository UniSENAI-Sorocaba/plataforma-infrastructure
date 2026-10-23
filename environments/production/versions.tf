terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # INF-001: descomentar quando o bootstrap do state existir na conta de produção.
  # backend "s3" {
  #   bucket       = "plataforma-tfstate-production"
  #   key          = "production/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}
