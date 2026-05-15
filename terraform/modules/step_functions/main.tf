resource "aws_sfn_state_machine" "datalake_pipeline" {
  name     = "${var.project}-${var.env}-pipeline"
  role_arn = var.sfn_role_arn

  definition = jsonencode({
    Comment = "Pipeline Bronze -> Silver -> Gold con Glue"
    StartAt = "dataQualityValidation"

    States = {
      dataQualityValidation = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.data_quality_job_name
        }
        Next = "bronzeToSilverJob"
      }

      bronzeToSilverJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.bronze_to_silver_job_name
        }
        Next = "silverToGoldJob"
      }

      silverToGoldJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.silver_to_gold_job_name
        }
        End = true
      }
    }
  })

  tags = var.tags
}
