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

# ─── S3 LAKE BUCKETS ──────────────────────────────────────────
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

# ─── GLUE JOB: Job_Exp_Terraform (data quality con Great Expectations) ──
module "glue_job" {
  source = "../../modules/glue"

  project = var.project
  env     = var.env

  # Job gestionado por Terraform. Le ponemos un nombre distinto del Job_Exp
  # creado manualmente en AWS para evitar colisión al hacer apply.
  # El Step Function de este módulo lo referencia automáticamente vía
  # module.glue_job.job_name (no hace falta hard-codearlo abajo).
  job_name = "Job_Exp_Terraform"

  glue_role_arn = module.iam.glue_role_arn

  bronze_bucket = module.bronze_bucket.bucket_name
  silver_bucket = module.silver_bucket.bucket_name
  temp_bucket   = module.bronze_bucket.bucket_name

  script_location = "s3://${module.bronze_bucket.bucket_name}/scripts/Job_Exp.py"

  tags = var.tags
}

# ─── IAM ROLES ────────────────────────────────────────────────
module "iam" {
  source = "../../modules/iam"

  project = var.project
  env     = var.env

  bronze_bucket = module.bronze_bucket.bucket_name
  silver_bucket = module.silver_bucket.bucket_name
  temp_bucket   = module.bronze_bucket.bucket_name
}

# ─── STEP FUNCTIONS ───────────────────────────────────────────
# Encadena: dataQualityValidation -> bronzeToSilverJob -> silverToGoldJob
# Job_Exp lo crea Terraform en este mismo apply.
# bronze_to_silver_taller y silver_to_gold_taller ya existen en AWS
# (creados manualmente en talleres previos); el Step Function los
# referencia por nombre.
module "step_functions" {
  source = "../../modules/step_functions"

  project      = var.project
  env          = var.env
  sfn_role_arn = module.iam.sfn_role_arn

  data_quality_job_name     = module.glue_job.job_name
  bronze_to_silver_job_name = "bronze_to_silver_taller"
  silver_to_gold_job_name   = "silver_to_gold_taller"

  tags = var.tags
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
