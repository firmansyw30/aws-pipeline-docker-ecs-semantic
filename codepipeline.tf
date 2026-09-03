# ──────────────────────────────────────────
# CODECOMMIT — EventBridge Rule to trigger pipeline
# ──────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "codecommit_trigger" {
  name        = var.codepipeline_trigger_name
  description = "Trigger CodePipeline on push to ${var.source_branch} branch"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = ["arn:aws:codecommit:${var.region}:${var.account_id}:${var.codecommit_repository_name}"]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = [var.source_branch]
    }
  })

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_cloudwatch_event_target" "codecommit_trigger_target" {
  rule     = aws_cloudwatch_event_rule.codecommit_trigger.name
  arn      = aws_codepipeline.geoserver_nodejs_pipeline.arn
  role_arn = aws_iam_role.codepipeline_service_role.arn
}

# ──────────────────────────────────────────
# CODEPIPELINE
# ──────────────────────────────────────────

resource "aws_codepipeline" "geoserver_nodejs_pipeline" {
  name           = var.codepipeline_name
  role_arn       = aws_iam_role.codepipeline_service_role.arn
  pipeline_type  = "V2"
  execution_mode = "QUEUED"

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifact.bucket
    type     = "S3"
  }

  # ── Stage 1: Source (CodeCommit) ──
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      run_order        = 1
      namespace        = "SourceVariables"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName       = var.codecommit_repository_name
        BranchName           = var.source_branch
        OutputArtifactFormat = "CODE_ZIP"
        PollForSourceChanges = "false"
      }
    }
  }

  # ── Stage 2: Build (CodeBuild → ECR) ──
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.geoserver_nodejs.name
      }
    }
  }

  # ── Stage 3: Deploy (ECS Fargate) ──
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      run_order       = 1
      input_artifacts = ["BuildArtifact"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "${var.container_name}-image-definitions.json"
      }
    }
  }

  depends_on = [
    aws_s3_bucket.codepipeline_artifact,
    aws_iam_role_policy_attachment.cp_ecr,
    aws_iam_role_policy_attachment.cp_codecommit,
    aws_iam_role_policy_attachment.cp_ecs,
    aws_iam_role_policy_attachment.cp_codebuild,
    aws_iam_role_policy_attachment.cp_s3,
    aws_codebuild_project.geoserver_nodejs
  ]

  tags = {
    Name        = var.codepipeline_name
    Environment = var.environment
    Owner       = var.owner
  }
}
