output "job_name" {
  description = "Nombre del Glue Job"
  value       = aws_glue_job.sales_etl.name
}