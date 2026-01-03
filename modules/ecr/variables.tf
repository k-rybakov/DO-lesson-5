variable "ecr_name" {
  description = "Назва ECR-репозиторію"
  type        = string
}

variable "scan_on_push" {
  description = "Чи увімкнути автоматичне сканування образів при пуші"
  type        = bool
  default     = true
}
