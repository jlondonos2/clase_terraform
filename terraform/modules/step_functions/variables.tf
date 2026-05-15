variable "project" {
  type        = string
  description = "Nombre del proyecto"
}

variable "env" {
  type        = string
  description = "Entorno (dev, prod, etc.)"
}

variable "sfn_role_arn" {
  type        = string
  description = "ARN del rol IAM para Step Functions"
}

variable "data_quality_job_name" {
  type        = string
  description = "Nombre del Glue Job de validación de calidad (dataQualityValidation)"
}

variable "bronze_to_silver_job_name" {
  type        = string
  description = "Nombre del Glue Job que mueve datos de Bronze a Silver"
}

variable "silver_to_gold_job_name" {
  type        = string
  description = "Nombre del Glue Job que mueve datos de Silver a Gold"
}

variable "tags" {
  type    = map(string)
  default = {}
}
