# ──────────────────────────────────────────
# S3 BUCKET — CodePipeline Artifact Store
# ──────────────────────────────────────────

resource "aws_s3_bucket" "codepipeline_artifact" {
  bucket        = var.artifact_bucket_name
  force_destroy = true

  tags = {
    Name        = var.artifact_bucket_name
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_s3_bucket_versioning" "codepipeline_artifact_versioning" {
  bucket = aws_s3_bucket.codepipeline_artifact.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifact_sse" {
  bucket = aws_s3_bucket.codepipeline_artifact.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifact_pab" {
  bucket                  = aws_s3_bucket.codepipeline_artifact.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
