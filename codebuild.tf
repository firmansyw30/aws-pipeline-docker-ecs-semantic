# ──────────────────────────────────────────
# CLOUDWATCH LOG GROUP — CodeBuild Logs
# ──────────────────────────────────────────

resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name              = "/aws/codebuild/${var.codebuild_project_name}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

# ──────────────────────────────────────────
# CODEBUILD PROJECT
# ──────────────────────────────────────────

resource "aws_codebuild_project" "geoserver_nodejs" {
  name          = var.codebuild_project_name
  description   = "Build and push prod-geoserver-nodejs Docker image to ECR"
  service_role  = aws_iam_role.codebuild_service_role.arn
  build_timeout = 60

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }

    environment_variable {
      name  = "ECR_REPO_URI"
      value = aws_ecr_repository.geoserver_nodejs.repository_url
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.geoserver_nodejs.name
    }

    environment_variable {
      name  = "IMAGE_DEFINITIONS_FILE"
      value = "${var.container_name}-image-definitions.json"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-BUILDSPEC
      version: 0.2
      phases:
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
            - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
            - BUILD_NUMBER=$CODEBUILD_BUILD_NUMBER
            - IMAGE_FULL_TAG="build-$BUILD_NUMBER-$IMAGE_TAG"
        build:
          commands:
            - echo Build started on `date`
            - echo Building the Docker image...
            - docker build -t $IMAGE_REPO_NAME:$IMAGE_FULL_TAG .
            - docker tag $IMAGE_REPO_NAME:$IMAGE_FULL_TAG $ECR_REPO_URI:$IMAGE_FULL_TAG
        post_build:
          commands:
            - echo Pushing the Docker image to ECR...
            - docker push $ECR_REPO_URI:$IMAGE_FULL_TAG
            - echo Writing image definitions file...
            - printf '[{"name":"${var.container_name}","imageUri":"%s"}]' $ECR_REPO_URI:$IMAGE_FULL_TAG > $IMAGE_DEFINITIONS_FILE
            - echo Build completed on `date`
      artifacts:
        files:
          - $IMAGE_DEFINITIONS_FILE
    BUILDSPEC
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild_logs.name
      stream_name = "build-log"
      status      = "ENABLED"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  cache {
    type = "NO_CACHE"
  }

  tags = {
    Name        = var.codebuild_project_name
    Environment = var.environment
    Owner       = var.owner
  }
}
