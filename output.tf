# ──────────────────────────────────────────
# OUTPUTS
# ──────────────────────────────────────────

output "codepipeline_arn" {
  description = "CodePipeline ARN"
  value       = aws_codepipeline.geoserver_nodejs_pipeline.arn
}

output "codepipeline_name" {
  description = "CodePipeline Name"
  value       = aws_codepipeline.geoserver_nodejs_pipeline.name
}

output "codebuild_project_name" {
  description = "CodeBuild Project Name"
  value       = aws_codebuild_project.geoserver_nodejs.name
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.geoserver_nodejs.repository_url
}

output "ecr_repository_name" {
  description = "ECR Repository Name"
  value       = aws_ecr_repository.geoserver_nodejs.name
}

output "codepipeline_service_role_arn" {
  description = "CodePipeline Service Role ARN"
  value       = aws_iam_role.codepipeline_service_role.arn
}

output "codebuild_service_role_arn" {
  description = "CodeBuild Service Role ARN"
  value       = aws_iam_role.codebuild_service_role.arn
}

output "artifact_bucket_name" {
  description = "S3 Artifact Bucket Name"
  value       = aws_s3_bucket.codepipeline_artifact.bucket
}

output "artifact_bucket_arn" {
  description = "S3 Artifact Bucket ARN"
  value       = aws_s3_bucket.codepipeline_artifact.arn
}

output "codecommit_trigger_arn" {
  description = "EventBridge rule ARN that triggers the pipeline"
  value       = aws_cloudwatch_event_rule.codecommit_trigger.arn
}
