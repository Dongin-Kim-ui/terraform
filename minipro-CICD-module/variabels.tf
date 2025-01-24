variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}


variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_branch" {
  description = "GitHub Branch"
  type        = string
  default     = "main"
}

variable "github_repository" {
  description = "GitHub Repository (format: username/repository)"
  type        = string
  default     = "Dongin-Kim-ui/AWS-CICD-HTML"
}

variable "github_repo_url" {
  description = "GitHub Repository URL"
  type        = string
}