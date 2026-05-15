resource "aws_sfn_state_machine" "datalake_pipeline" {
  name     = "${var.project}-${var.env}-pipeline"
  role_arn = var.sfn_role_arn

  definition = jsonencode({
    Comment = "Pipeline Data Lake: Bronze → Silver"
    StartAt = "RunGlueJob"

    States = {
      RunGlueJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.glue_job_name
        }
        Next = "JobSuccess"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "JobFailed"
        }]
      }

      JobSuccess = {
        Type = "Succeed"
      }

      JobFailed = {
        Type  = "Fail"
        Error = "GlueJobFailed"
        Cause = "El job de Glue falló"
      }
    }
  })

  tags = var.tags
}