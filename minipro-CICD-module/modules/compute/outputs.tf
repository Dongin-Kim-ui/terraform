output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.myEC2.id
}

output "public_ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.myEC2.public_ip
}

output "ec2_instance_dns" {
  description = "EC2 Instance DNS"
  value       = aws_instance.myEC2.public_dns
}

output "ec2_tag_value" {
  description = "EC2 Instance Name Tag Value"
  value       = aws_instance.myEC2.tags["Name"]
}
