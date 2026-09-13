terraform {
  required_version = ">= 1.8.0, < 2.0.0"
}

# Production usa conta, state e aprovação separados de non-production.
locals { environment = "production" }
