resource "aws_s3_bucket" "this" {
  bucket = "${var.project}-${var.env}-${var.bucket_name}-${var.account_id}"

  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "transition-old-data"
    status = "Enabled"

    transition {
      days          = 180
      storage_class = "STANDARD_IA"
    }
  }
}