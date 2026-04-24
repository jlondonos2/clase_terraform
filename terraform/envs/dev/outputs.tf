output "bronze_bucket_name" {
  value = module.bronze_bucket.bucket_name
}

output "silver_bucket_name" {
  value = module.silver_bucket.bucket_name
}

output "gold_bucket_name" {
  value = module.gold_bucket.bucket_name
}