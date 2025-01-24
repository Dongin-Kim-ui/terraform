# CodeStar Connection 생성
resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

# CodeBuild 프로젝트 생성
resource "aws_codebuild_project" "html_project" {
  name          = "html-project"
  description   = "HTML 프로젝트를 위한 CodeBuild 프로젝트"
  build_timeout = "5"
  service_role  = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        install:
          runtime-versions:
            nodejs: 18
        pre_build:
          commands:
            - echo Pre-build phase started
            - echo Nothing to do in pre-build
        build:
          commands:
            - echo Build phase started
            - echo Nothing to build for static HTML
        post_build:
          commands:
            - echo Post-build phase started
            - echo Copying HTML files
      artifacts:
        files:
          - '**/*'
    EOT
  }
}

# GitHub 인증 설정
resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}

# CodeDeploy 애플리케이션 생성
resource "aws_codedeploy_app" "html_app" {
  name             = "MyHtml"
  compute_platform = "Server"
}

# CodeDeploy 배포 그룹 생성
resource "aws_codedeploy_deployment_group" "html_deployment_group" {
  app_name               = aws_codedeploy_app.html_app.name
  deployment_group_name  = "HTMLDeployGroup"
  service_role_arn      = var.codedeploy_role_arn

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.ec2_tag_value
    }
  }

  deployment_config_name = "CodeDeployDefault.AllAtOnce"
}

# CodePipeline 생성
resource "aws_codepipeline" "html_pipeline" {
  name     = "html-pipeline"
  role_arn = var.pipeline_role_arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repository
        BranchName      = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner          = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version        = "1"

      configuration = {
        ProjectName = aws_codebuild_project.html_project.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner          = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version        = "1"

      configuration = {
        ApplicationName = aws_codedeploy_app.html_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.html_deployment_group.deployment_group_name
      }
    }
  }
}

# S3 버킷 생성 (아티팩트 저장용)
resource "aws_s3_bucket" "artifact_store" {
  bucket        = "html-pipeline-artifact-${random_string.bucket_suffix.result}"
  force_destroy = true
}

# 랜덤 문자열 생성 (버킷 이름 충돌 방지)
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 버킷 버전 관리 활성화
resource "aws_s3_bucket_versioning" "artifact_store" {
  bucket = aws_s3_bucket.artifact_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "artifact_store" {
  bucket = aws_s3_bucket.artifact_store.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 버킷 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "artifact_store" {
  bucket = aws_s3_bucket.artifact_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}