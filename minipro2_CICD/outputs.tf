output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.myEC2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.myEC2.public_dns
}
