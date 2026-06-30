variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para todos los recursos"
  type        = string
  default     = "leccion4"
}

variable "environment" {
  type    = string
  default = "dev"
}
