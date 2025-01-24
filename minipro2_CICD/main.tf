resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

# CodeBuild 역할에 정책 연결
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = ["*"]
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:*",
          "codecommit:*",
          "codestar-connections:UseConnection"
        ]
      }
    ]
  })
}

# CodeBuild 프로젝트 생성
resource "aws_codebuild_project" "html_project" {
  name          = "html-project"
  description   = "HTML 프로젝트를 위한 CodeBuild 프로젝트"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

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
    buildspec = <<-EOF
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
      - echo Copying HTML files to build output
      - mkdir -p /codebuild/output/src2043122978/src/
      - cp -r * /codebuild/output/src2043122978/src/

artifacts:
  files:
    - '**/*'
  base-directory: /codebuild/output/src2043122978/src
    EOF
  }

  source_version = "main"
}

# GitHub 자격 증명 설정
resource "aws_codebuild_source_credential" "github_credential" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token  # GitHub Personal Access Token을 변수로 설정
}

resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "Allow SSH,HTTP inbound traffic and all outbound traffic"

  tags = {
    Name = "mysg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports  -1 = 모든 프로토콜
}

# EC2용 IAM 역할 생성
resource "aws_iam_role" "ec2_role" {
  name = "EC2-HTMLDeploy-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# AWSCodeDeployFullAccess 정책 연결
resource "aws_iam_role_policy_attachment" "codedeploy_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
  role       = aws_iam_role.ec2_role.name
}

# AmazonSSMManagedInstanceCore 정책 연결
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}

# S3FullAccess 정책 연결 추가
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.ec2_role.name
}

# EC2 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-HTMLDeploy-Profile"
  role = aws_iam_role.ec2_role.name
}

# 최신 Amazon Linux 2 AMI 가져오기
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 인스턴스 생성
resource "aws_instance" "myEC2" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  
  key_name               = "mykeypair2"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              # 로그 파일 생성
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              # 시스템 업데이트
              yum update -y
              
              # Apache 설치 및 시작
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              
              # CodeDeploy Agent 설치 준비
              yum install -y ruby wget
              
              # CodeDeploy Agent 설치
              cd /home/ec2-user
              wget https://aws-codedeploy-${data.aws_region.current.name}.s3.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto
              
              # CodeDeploy Agent 상태 확인
              service codedeploy-agent status
              
              # 웹 서버 디렉토리 설정
              mkdir -p /var/www/html/
              chmod 755 /var/www/html/
              chown -R ec2-user:apache /var/www/html/
              
              # 테스트 페이지 생성
              echo "<html><body><h1>Hello from EC2</h1></body></html>" > /var/www/html/index.html
              
              # SELinux 설정 (필요한 경우)
              setsebool -P httpd_can_network_connect 1
              
              # Apache 재시작
              systemctl restart httpd
              EOF

  tags = {
    Name = "myEC2"
  }

  # 인스턴스가 완전히 시작될 때까지 대기
  root_block_device {
    delete_on_termination = true
    volume_size           = 8
  }
}

# 현재 리전 정보 가져오기
data "aws_region" "current" {}

# CodeDeploy IAM Role
resource "aws_iam_role" "codedeploy_service_role" {
  name = "CodeDeploy-Service-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

# CodeDeploy IAM Role Policy 연결
resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_service_role.name
}

# CodeDeploy Application 생성
resource "aws_codedeploy_app" "html_app" {
  name             = "MyHtml"
  compute_platform = "Server"  # EC2/On-premises를 의미
}

# CodeDeploy Deployment Group 생성
resource "aws_codedeploy_deployment_group" "html_deployment_group" {
  app_name               = aws_codedeploy_app.html_app.name
  deployment_group_name  = "HTMLDeployGroup"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "myEC2"
    }
  }

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

# CodePipeline을 위한 S3 버킷 생성
resource "aws_s3_bucket" "artifact_store" {
  bucket = "html-pipeline-artifact-store-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# 현재 AWS 계정 ID 가져오기
data "aws_caller_identity" "current" {}


# CodePipeline IAM Role
resource "aws_iam_role" "pipeline_role" {
  name = "AWSCodePipelineServiceRole-us-east-2-HTMLPipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

# CodePipeline IAM Role Policy
resource "aws_iam_role_policy" "pipeline_policy" {
  name = "pipeline-policy"
  role = aws_iam_role.pipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "codecommit:*",
          "codebuild:*",
          "codedeploy:*",
          "codestar-connections:UseConnection",
          "codestar-connections:PassConnection"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeStar Connection 생성
resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
  tags = {
    Name = "GitHub Connection"
  }
}

# CodePipeline 생성
resource "aws_codepipeline" "html_pipeline" {
  name     = "HTMLPipeline"
  role_arn = aws_iam_role.pipeline_role.arn

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
      output_artifacts = ["SourceArtifact"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repository
        BranchName      = var.github_branch
        DetectChanges   = true
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["SourceArtifact"]
      version         = "1"
      
      configuration = {
        ProjectName = "html-project"
      }
      
      output_artifacts = ["BuildArtifact"]
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["BuildArtifact"]

      configuration = {
        ApplicationName = aws_codedeploy_app.html_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.html_deployment_group.deployment_group_name
      }
    }
  }
}

# EC2 IAM 역할에 추가 정책 연결
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ec2_role.name
}
