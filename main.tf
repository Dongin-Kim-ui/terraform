terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

module "cicd" {
  source = "./minipro2_CICD"
  
  # 필요한 변수들 전달
  github_token = var.github_token
  github_repository = var.github_repository
  github_branch = var.github_branch
  github_repo_url = var.github_repo_url
}

# 메인 디렉토리의 variables.tf에도 변수 선언 필요
variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_repository" {
  description = "GitHub Repository (format: username/repository)"
  type        = string
  default     = "Dongin-Kim-ui/AWS-CICD-HTML"
}

variable "github_branch" {
  description = "GitHub Branch"
  type        = string
  default     = "main"
}

variable "github_repo_url" {
  description = "GitHub Repository URL"
  type        = string
} 