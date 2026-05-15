
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