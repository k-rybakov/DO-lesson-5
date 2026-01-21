# Aurora endpoints and connection details
output "aurora_cluster_endpoint" {
  description = "Aurora cluster write endpoint"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : null
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster read-only endpoint"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

# Standard RDS endpoint and connection details
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = !var.use_aurora ? aws_db_instance.standard[0].endpoint : null
}

# Port
output "database_port" {
  description = "Database port"
  value       = 5432
}

# Connection URLs
output "aurora_connection_url" {
  description = "Aurora cluster connection URL (write endpoint)"
  value = var.use_aurora ? format(
    "postgresql://%s:%s@%s:5432/%s",
    var.username,
    "<password>",
    aws_rds_cluster.aurora[0].endpoint,
    var.db_name
  ) : null
}

output "rds_connection_url" {
  description = "RDS instance connection URL"
  value = !var.use_aurora ? format(
    "postgresql://%s:%s@%s:5432/%s",
    var.username,
    "<password>",
    aws_db_instance.standard[0].endpoint,
    var.db_name
  ) : null
}

# Database name and credentials info
output "database_name" {
  description = "Database name"
  value       = var.db_name
}

output "database_username" {
  description = "Database master username"
  value       = var.username
}
