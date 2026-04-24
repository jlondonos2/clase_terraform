terraform {
  backend "s3" {
    bucket         = "datalake-terraform-state-670578095526"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

module "bronze_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  bucket_name = "bronze"
  account_id  = data.aws_caller_identity.current.account_id
  tags        = var.tags
}

module "silver_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  bucket_name = "silver"
  account_id  = data.aws_caller_identity.current.account_id
  tags        = var.tags
}

module "gold_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  bucket_name = "gold"
  account_id  = data.aws_caller_identity.current.account_id
  tags        = var.tags
}

module "glue_job" {
  source = "../../modules/glue"

  project = var.project
  env     = var.env

  glue_role_arn = module.iam.glue_role_arn

  bronze_bucket = module.bronze_bucket.bucket_name
  silver_bucket = module.silver_bucket.bucket_name
  temp_bucket   = module.bronze_bucket.bucket_name

  script_location = "s3://${module.bronze_bucket.bucket_name}/scripts/etl_sales.py"



  tags = var.tags
}

module "iam" {
  source = "../../modules/iam"

  project = var.project
  env     = var.env

  bronze_bucket = module.bronze_bucket.bucket_name
  silver_bucket = module.silver_bucket.bucket_name
  temp_bucket   = module.bronze_bucket.bucket_name
}
