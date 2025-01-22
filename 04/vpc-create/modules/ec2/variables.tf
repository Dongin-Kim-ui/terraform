variable "instance_type" {
  default     = "t2.micro"
  description = "Instance Type"
  type        = string
}

variable "ec2tag" {
  default = {
    Name = "myec2"
  }
  description = "EC2 Instance Tag"
  type        = map(string)
}


# 필수 입력 사항
variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "sg_ids" {
  description = "Security Group IDs"
  type = list
}

variable "keypair" {
  description = "EC2 Key Pair"
  type = string
}