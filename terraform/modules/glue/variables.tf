variable "project" {}
variable "env" {}
variable "glue_role_arn" {}
variable "script_location" {}
variable "job_name" {
  description = "Nombre exacto del Glue Job en AWS (debe coincidir con el referenciado en Step Functions)"
  type        = string
}

variable "bronze_bucket" {}
variable "silver_bucket" {}
variable "temp_bucket" {}

variable "tags" {
  type = map(string)
}
