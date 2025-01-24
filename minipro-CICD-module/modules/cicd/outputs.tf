output "codebuild_project_name" {
  description = "CodeBuild Project Name"
  value       = aws_codebuild_project.html_project.name
}

output "codedeploy_app_name" {
  description = "CodeDeploy Application Name"
  value       = aws_codedeploy_app.html_app.name
}

output "deployment_group_name" {
  description = "CodeDeploy Deployment Group Name"
  value       = aws_codedeploy_deployment_group.html_deployment_group.deployment_group_name
}
