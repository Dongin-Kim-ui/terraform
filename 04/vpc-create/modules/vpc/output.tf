output "vpc_id" {
  value       = aws_vpc.MyVPC.id
  description = "VPC ID"
}

output "subnet_id" {
  value       = aws_subnet.mysubnet.id
  description = "Subnet ID"
}

output "sg_id" {
  value = aws_security_group.mysg.id
  description = "Security Group"
}