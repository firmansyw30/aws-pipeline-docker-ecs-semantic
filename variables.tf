# ──────────────────────────────────────────
# VARIABLES
# ──────────────────────────────────────────

variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-3"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
  default     = "392987323540"
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Resource owner tag"
  type        = string
  default     = "firman_devops"
}

# ── S3 ──
variable "artifact_bucket_name" {
  description = "Name of the S3 bucket used as the CodePipeline artifact store"
  type        = string
  default     = "geoserver-codepipeline-artifact-new"
}

# ── ECR ──
variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "prod-geoserver-nodejs-revision-new"
}

# ── IAM ──
variable "codepipeline_service_role_name" {
  description = "Name of the CodePipeline service role"
  type        = string
  default     = "codepipeline-default-service-role-new"
}

variable "codebuild_service_role_name" {
  description = "Name of the CodeBuild service role"
  type        = string
  default     = "codebuild-geoserver-nodejs-service-role-new"
}

variable "codebuild_policy_name" {
  description = "Name of the CodeBuild inline policy"
  type        = string
  default     = "codebuild-geoserver-nodejs-policy"
}

# ── CodeBuild ──
variable "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = "prod-geoserver-nodejs-codebuild-project-revision-new"
}

variable "container_name" {
  description = "ECS container name referenced in the image definitions file"
  type        = string
  default     = "prod-geoserver-nodejs-revision"
}

# ── CodeCommit / Pipeline ──
variable "codecommit_repository_name" {
  description = "Name of the CodeCommit source repository"
  type        = string
  default     = "geoserver"
}

variable "source_branch" {
  description = "Branch that triggers the pipeline"
  type        = string
  default     = "ecr-prod"
}

variable "codepipeline_name" {
  description = "Name of the CodePipeline"
  type        = string
  default     = "prod-geoserver-nodejs-pipeline-revision-new"
}

variable "codepipeline_trigger_name" {
  description = "Name of the EventBridge rule that triggers the pipeline"
  type        = string
  default     = "prod-geoserver-nodejs-pipeline-trigger-new"
}

# ── ECS ──
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster that receives the deploy"
  type        = string
  default     = "prodserver-mapid-cluster-new"
}

variable "ecs_service_name" {
  description = "Name of the ECS service that receives the deploy"
  type        = string
  default     = "prod-geoserver-nodejs-revision-service-new"
}
