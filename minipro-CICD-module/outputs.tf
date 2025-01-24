output "instance_public_ip" {
  description = "EC2 Instance Public IP"
  value       = module.compute.public_ip
}

output "codebuild_project_name" {
  description = "CodeBuild Project Name"
  value       = module.cicd.codebuild_project_name
}

output "codedeploy_app_name" {
  description = "CodeDeploy Application Name"
  value       = module.cicd.codedeploy_app_name
}

output "deployment_group_name" {
  description = "CodeDeploy Deployment Group Name"
  value       = module.cicd.deployment_group_name
}


output "instance_dns_name" {
  description = "EC2 Instance DNS"
  value       = module.compute.ec2_instance_dns
}

