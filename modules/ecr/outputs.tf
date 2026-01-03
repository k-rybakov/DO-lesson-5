output "repository_url" {
  description = "URL (registry URI) ECR-репозиторію"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN ECR-репозиторію"
  value       = aws_ecr_repository.this.arn
}
