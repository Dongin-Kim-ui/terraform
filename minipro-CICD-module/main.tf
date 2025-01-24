terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "iam" {
  source = "./modules/iam" # 경로 확인
}

module "network" {
  source = "./modules/network" # 경로 확인
}

module "compute" {
  source = "./modules/compute" # 경로 확인

  instance_type        = var.instance_type
  key_name             = var.key_name
  security_group_id    = module.network.security_group_id
  iam_instance_profile = module.iam.ec2_instance_profile_name
  aws_region           = var.aws_region
}

module "cicd" {
  source = "./modules/cicd"

  github_repo_url     = "https://github.com/Dongin-Kim-ui/AWS-CICD-HTML.git"
  github_token        = var.github_token
  codebuild_role_arn  = module.iam.codebuild_role_arn
  codedeploy_role_arn = module.iam.codedeploy_role_arn
  pipeline_role_arn   = module.iam.pipeline_role_arn
  ec2_tag_value       = module.compute.ec2_tag_value
  account_id          = data.aws_caller_identity.current.account_id
}

# AWS 계정 ID 가져오기
data "aws_caller_identity" "current" {}