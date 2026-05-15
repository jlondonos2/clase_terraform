terraform {
  backend "s3" {
    bucket         = "datalake-terraform-state-140116241247"
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
  bucket_name = "raw"
  account_id  = data.aws_caller_identity.current.account_id
  tags        = var.tags
}

module "silver_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  bucket_name = "staging"
  account_id  = data.aws_caller_identity.current.account_id
  tags        = var.tags
}

module "gold_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  bucket_name = "analytics"
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

  script_location = "s3://${module.bronze_bucket.bucket_name}/scripts/Job_Exp.py"



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

# ─── STEP FUNCTIONS ───────────────────────────────────────────
module "step_functions" {
  source = "../../modules/step_functions"

  project       = var.project
  env           = var.env
  sfn_role_arn  = module.iam.sfn_role_arn
  glue_job_name = module.glue_job.job_name
  tags          = var.tags
}

# ─── SUBIR ARCHIVOS A S3 ──────────────────────────────────────

resource "aws_s3_object" "hurto_csv" {
  bucket = module.bronze_bucket.bucket_name
  key    = "data/hurto_transporte_publico.csv"
  source = "${path.root}/../../archivos_para_bronze/hurto_transporte_publico.csv"
  etag   = filemd5("${path.root}/../../archivos_para_bronze/hurto_transporte_publico.csv")
}

resource "aws_s3_object" "glue_script" {
  bucket = module.bronze_bucket.bucket_name
  key    = "scripts/Job_Exp.py"
  source = "${path.root}/../../archivos_para_bronze/scripts/Job_Exp.py"
  etag   = filemd5("${path.root}/../../archivos_para_bronze/scripts/Job_Exp.py")
}