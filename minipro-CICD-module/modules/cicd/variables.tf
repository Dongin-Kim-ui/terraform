variable "codebuild_role_arn" {
  description = "CodeBuild IAM Role ARN"
  type        = string
}

variable "codedeploy_role_arn" {
  description = "CodeDeploy IAM Role ARN"
  type        = string
}

variable "pipeline_role_arn" {
  description = "CodePipeline IAM Role ARN"
  type        = string
}

variable "ec2_tag_value" {
  description = "EC2 Instance Name Tag Value"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "github_repo_url" {
  description = "GitHub Repository URL"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_repository" {
  description = "GitHub Repository (format: owner/repo)"
  type        = string
  default     = "Dongin-Kim-ui/AWS-CICD-HTML"
}