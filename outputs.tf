output "ec2_instance_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.cicd.ec2_public_dns
}

output "ec2_instance_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.cicd.ec2_public_ip
} 