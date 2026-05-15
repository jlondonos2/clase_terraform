resource "aws_glue_job" "this" {
  name     = var.job_name
  role_arn = var.glue_role_arn

  command {
    name            = "glueetl"
    script_location = var.script_location
    python_version  = "3"
  }

  default_arguments = {
    "--input_path"                = "s3://${var.bronze_bucket}/data/hurto_transporte_publico.csv"
    "--output_path"               = "s3://${var.silver_bucket}/validation_results/"
    "--TempDir"                   = "s3://${var.temp_bucket}/temp/"
    "--additional-python-modules" = "great_expectations"
  }

  worker_type       = "G.1X"
  number_of_workers = 2

  glue_version = "5.0"

  timeout = 10

  tags = var.tags
}

moved {
  from = aws_glue_job.sales_etl
  to   = aws_glue_job.this
}
