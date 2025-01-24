output "codebuild_role_arn" {
  description = "CodeBuild IAM Role ARN"
  value       = aws_iam_role.codebuild_role.arn
}

output "codedeploy_role_arn" {
  description = "CodeDeploy IAM Role ARN"
  value       = aws_iam_role.codedeploy_service_role.arn
}

output "pipeline_role_arn" {
  description = "CodePipeline IAM Role ARN"
  value       = aws_iam_role.pipeline_role.arn
}

output "ec2_instance_profile_name" {
  description = "EC2 Instance Profile Name"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_role_name" {
  description = "EC2 IAM Role Name"
  value       = aws_iam_role.ec2_role.name
}