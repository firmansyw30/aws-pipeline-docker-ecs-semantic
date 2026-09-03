# aws-pipeline-docker-ecs-semantic

AWS CI/CD pipeline that builds a Docker image with **CodeBuild** (semantic tagging), pushes it to **ECR**, and deploys it to **ECS Fargate**. The pipeline is triggered automatically via an **EventBridge** rule on every push to a configured branch.

> Infrastructure is defined with **Terraform** and organized per service into separate `.tf` files.

---

## Architecture

```
CodeCommit (branch) ──▶ CodePipeline ──▶ CodeBuild ──▶ ECR ──▶ ECS (Fargate)
                             ▲               │
                             └── artifacts stored in S3 bucket
```

1. **Source** – A push to the configured branch in CodeCommit triggers the pipeline via EventBridge.
2. **Build** – CodeBuild logs in to ECR, builds the Docker image, tags it (`build-<buildNumber>-<sha>`), and pushes it to ECR.
3. **Deploy** – CodePipeline deploys the new image to the ECS service using the generated image definitions file.

---

## Repository Layout

| File                    | Purpose                                                                 |
|-------------------------|-------------------------------------------------------------------------|
| `terraform.tf`          | Terraform/Provider configuration (AWS provider `~> 5.0`)                |
| `variables.tf`          | Input variables (region, account, names, tags) with defaults            |
| `s3.tf`                 | S3 artifact store bucket (versioning, SSE, public-access block)         |
| `ecr.tf`                | ECR repository + lifecycle policy                                       |
| `iam.tf`                | CodePipeline & CodeBuild service roles and policies                     |
| `codebuild.tf`          | CloudWatch log group + CodeBuild project (with buildspec)               |
| `codepipeline.tf`       | CodePipeline (3 stages) + EventBridge trigger rule/target               |
| `output.tf`             | Terraform outputs                                                       |
| `terraform.tfvars`      | Actual variable values (production)                                     |
| `terraform.tfvars.example` | Template to copy into `terraform.tfvars`                              |

---

## Resources Created

The following AWS resources are provisioned:

- **S3** – `geoserver-codepipeline-artifact-new` (artifact store; versioning + AES256 SSE + full public access block)
- **ECR** – `prod-geoserver-nodejs-revision-new` (immutable tags, scan on push; lifecycle keeps last 10 `build-` tags and expires untagged images after 7 days)
- **IAM** – `codepipeline-default-service-role-new` and `codebuild-geoserver-nodejs-service-role-new` with their managed/inline policies
- **CloudWatch** – CodeBuild log group (30-day retention)
- **CodeBuild** – `prod-geoserver-nodejs-codebuild-project-revision-new`
- **EventBridge** – `prod-geoserver-nodejs-pipeline-trigger-new` (fires on branch push)
- **CodePipeline** – `prod-geoserver-nodejs-pipeline-revision-new` (Source → Build → Deploy)

---

## Usage

### Prerequisites

- Terraform `>= 1.0`
- AWS credentials configured (e.g. environment variables or a profile)
- The target CodeCommit repository, ECS cluster, and ECS service already exist

### Quick Start

```bash
# 1. Configure variable values
cp terraform.tfvars.example terraform.tfvars

# 2. Initialize providers
terraform init

# 3. Preview the changes
terraform plan

# 4. Apply
terraform apply
```

### Inputs

| Variable                       | Type   | Default                                         | Description                                      |
|--------------------------------|--------|-------------------------------------------------|--------------------------------------------------|
| `region`                       | string | `ap-southeast-3`                                | AWS region for resources                         |
| `account_id`                   | string | `392987323540`                                  | AWS account ID                                   |
| `environment`                  | string | `prod`                                          | Deployment environment tag                       |
| `owner`                        | string | `firman_devops`                                 | Resource owner tag                               |
| `artifact_bucket_name`         | string | `geoserver-codepipeline-artifact-new`           | S3 artifact store bucket                         |
| `ecr_repository_name`          | string | `prod-geoserver-nodejs-revision-new`            | ECR repository name                              |
| `codepipeline_service_role_name` | string | `codepipeline-default-service-role-new`       | CodePipeline service role name                   |
| `codebuild_service_role_name`  | string | `codebuild-geoserver-nodejs-service-role-new`   | CodeBuild service role name                      |
| `codebuild_policy_name`        | string | `codebuild-geoserver-nodejs-policy`             | CodeBuild inline policy name                     |
| `codebuild_project_name`       | string | `prod-geoserver-nodejs-codebuild-project-revision-new` | CodeBuild project name                   |
| `container_name`               | string | `prod-geoserver-nodejs-revision`                | ECS container name (image definitions file)      |
| `codecommit_repository_name`   | string | `geoserver`                                     | CodeCommit source repository                     |
| `source_branch`                | string | `ecr-prod`                                      | Branch that triggers the pipeline                |
| `codepipeline_name`            | string | `prod-geoserver-nodejs-pipeline-revision-new`   | CodePipeline name                                |
| `codepipeline_trigger_name`    | string | `prod-geoserver-nodejs-pipeline-trigger-new`    | EventBridge trigger rule name                    |
| `ecs_cluster_name`             | string | `prodserver-mapid-cluster-new`                  | ECS cluster receiving the deploy                 |
| `ecs_service_name`             | string | `prod-geoserver-nodejs-revision-service-new`    | ECS service receiving the deploy                 |

### Outputs

| Name                          | Description                        |
|-------------------------------|------------------------------------|
| `codepipeline_arn`            | CodePipeline ARN                   |
| `codepipeline_name`           | CodePipeline name                  |
| `codebuild_project_name`      | CodeBuild project name             |
| `ecr_repository_url`          | ECR repository URL                 |
| `ecr_repository_name`         | ECR repository name                |
| `codepipeline_service_role_arn` | CodePipeline service role ARN    |
| `codebuild_service_role_arn`  | CodeBuild service role ARN         |
| `artifact_bucket_name`        | S3 artifact bucket name            |
| `artifact_bucket_arn`         | S3 artifact bucket ARN             |
| `codecommit_trigger_arn`      | EventBridge rule ARN (pipeline trigger) |

---

## Image Definition File

During the `post_build` phase, CodeBuild writes an **image definitions** JSON file (`<container_name>-image-definitions.json`) containing the built image URI. CodePipeline's ECS deploy action consumes this file to update the target service.

```json
[{"name":"<container_name>","imageUri":"<ecr-repo>:build-<buildNumber>-<sha>"}]
```

---

## Notes

- The pipeline uses `PollForSourceChanges = false` and relies on the **EventBridge** rule for triggering, so no polling is needed.
- ECS cluster and service referenced in the Deploy stage are expected to already exist (`ecs_cluster_name` / `ecs_service_name`).
- ECR repository uses immutable tags and has image scanning enabled on push.
