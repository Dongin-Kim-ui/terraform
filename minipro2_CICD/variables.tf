variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_repository" {
  description = "GitHub Repository (format: username/repository)"
  type        = string
}

variable "github_branch" {
  description = "GitHub Branch"
  type        = string
}

variable "github_repo_url" {
  description = "GitHub Repository URL"
  type        = string
}

