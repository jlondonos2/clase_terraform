
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

variable "glue_job_name" {
  type        = string
  description = "Nombre del Glue Job"
}

variable "tags" {
  type    = map(string)
  default = {}
}