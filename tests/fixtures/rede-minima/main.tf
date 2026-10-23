# Fixture: rede mínima para testar módulos ANTES do modules/network ficar pronto.
# Expõe os mesmos nomes de output do contrato do network. Uso: docs/02-testar-no-ministack.md
terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

data "aws_availability_zones" "this" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block = "10.99.0.0/16"
  tags       = { Name = "teste-fixture" }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.this.names[count.index]
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.this.names[count.index]
}

resource "aws_security_group" "alb" {
  name   = "teste-fixture-alb"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group" "app" {
  name   = "teste-fixture-app"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group" "db" {
  name   = "teste-fixture-db"
  vpc_id = aws_vpc.this.id
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}
