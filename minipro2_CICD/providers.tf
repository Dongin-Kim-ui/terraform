provider "aws" {
  region = "us-east-2"
}

provider "github" {
  token = var.github_token
  owner = "Dongin-Kim-ui"
}

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}