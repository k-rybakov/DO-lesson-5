variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "" # Оставить пустым или удалить default
}