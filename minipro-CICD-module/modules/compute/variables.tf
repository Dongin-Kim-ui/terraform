variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}