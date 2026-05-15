output "bronze_bucket_name" {
  value = module.bronze_bucket.bucket_name
}

output "silver_bucket_name" {
  value = module.silver_bucket.bucket_name
}

output "gold_bucket_name" {
  value = module.gold_bucket.bucket_name
}

output "state_machine_arn" {
  value = module.step_functions.state_machine_arn
}

output "glue_job_name" {
  value = module.glue_job.job_name
}