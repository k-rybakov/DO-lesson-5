output "s3_bucket_name" {
  description = "Назва S3-бакета для стейтів"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Назва таблиці DynamoDB для блокування стейтів"
  value       = module.s3_backend.dynamodb_table_name
}

output "repository_url" {
  description = "URL (registry URI) ECR-репозиторію"
  value       = module.ecr.repository_url
}

output "repository_arn" {
  description = "ARN ECR-репозиторію"
  value       = module.ecr.repository_arn
}

output "vpc_id" {
  description = "ID створеної VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Список ID публічних підмереж"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Список ID приватних підмереж"
  value       = module.vpc.private_subnets
}

output "internet_gateway_id" {
  description = "ID Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "aws_eip_id" {
  description = "ID Elastic IP"
  value       = module.vpc.aws_eip_id
}

output "aws_nat_gateway_id" {
  description = "ID NAT Gateway"
  value       = module.vpc.aws_nat_gateway_id
}