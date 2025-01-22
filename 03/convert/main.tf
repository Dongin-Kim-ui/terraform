# aws provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# 1. VPC 설정
# Resource: aws_vpc
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
# * enable_dns_hostnames = true

resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "myVPC"
  }
}

# Resource: aws_internet_gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

# Resource: aws_route_table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "MyPublicRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }


  tags = {
    Name = "MyPublicRT"
  }
}

# Resource: aws_subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

data "aws_availability_zones" "available" {}

resource "aws_subnet" "MyPublicSN1" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "MyPublicSN1"
  }
}

resource "aws_subnet" "MyPublicSN2" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true
  tags = {
    Name = "MyPublicSN1"
  }
}

# Resource: aws_route_table_association
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.MyPublicSN1.id
  route_table_id = aws_route_table.MyPublicRT.id
}


resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.MyPublicSN2.id
  route_table_id = aws_route_table.MyPublicRT.id
}


# Resource: aws_security_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "allow_SG" {
  name        = "allow_SG"
  description = "Allow ssh http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "allow_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ssh" {
  security_group_id = aws_security_group.allow_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_http" {
  security_group_id = aws_security_group.allow_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Resource: aws_instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

data "aws_ami" "Amazon_Linux_2023_AMI" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.*.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}


resource "aws_instance" "MYEC21" {
  ami                    = data.aws_ami.Amazon_Linux_2023_AMI.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.MyPublicSN1.id
  vpc_security_group_ids = [aws_security_group.allow_SG.id]
  user_data              = file("myEC2tm.tpl")
  tags = {
    Name = "MYEC21"
  }
}

resource "aws_instance" "MYEC22" {
  ami                    = data.aws_ami.Amazon_Linux_2023_AMI.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.MyPublicSN2.id
  vpc_security_group_ids = [aws_security_group.allow_SG.id]
  user_data              = file("myEC2tm2.tpl")
  tags = {
    Name = "MYEC22"
  }
}

# Resource: aws_lb_target_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "My-ALB-TG" {
  name     = "My-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myVPC.id
}

resource "aws_lb_target_group_attachment" "TG_att1" {
  target_group_arn = aws_lb_target_group.My-ALB-TG.arn
  target_id        = aws_instance.MYEC21.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "TG_att2" {
  target_group_arn = aws_lb_target_group.My-ALB-TG.arn
  target_id        = aws_instance.MYEC22.id
  port             = 80
}

# Resource: aws_lb
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "My-ALB" {
  name               = "My-ALB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_SG.id]
  subnets            = [aws_subnet.MyPublicSN1.id, aws_subnet.MyPublicSN2.id]
}

# Resource: aws_lb_listener
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener

resource "aws_lb_listener" "my-alb-listner" {
  load_balancer_arn = aws_lb.My-ALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.My-ALB-TG.arn
  }
}

