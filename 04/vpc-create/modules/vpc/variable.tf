variable "vpc_id" {
  default     = "10.0.0.0/16"
  description = "VPC CIDR"
  type        = string
}


variable "vpc_tag" {
  default = {
    Name = "MyVPC"
  }
  description = "VPC tag"
  type        = map(string)
}

variable "igw_tag" {
  default = {
    Name = "Myigw"
  }
  description = "IGW tag"
  type        = map(string)
}

variable "subnet_cidr" {
  default     = "10.0.1.0/24"
  description = "VPC Public Subnet"
  type        = string
}

variable "subnet_tag" {
  default = {
    Name = "mysubnet"
  }
  description = "subnet tag"
  type        = map(string)
}

variable "routetable_tag" {
  default = {
    Name = "mypubtable"
  }
  description = "routing table tag"
  type        = map(string)
}

variable "mysg_tag" {
  default = {
    Name = "mysg"
  }
  description = "mysg Tag"
  type = map(string)
}