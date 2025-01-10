# 1. Provider 설정
provider "aws" {
  region = "us-east-2"
}
# 2. VPC  생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}

# 3. Internet Gateway 생성
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    Name = "myIGW"
  }
}


# 4. public Subnet 생성
resource "aws_subnet" "myPubSubnet" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSubnet"
  }
}

# 5. Public Routing Table 생성 & Public Subnet에 연결

resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }


  tags = {
    Name = "myPubRT"
  }
}


resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSubnet.id
  route_table_id = aws_route_table.myPubRT.id
}


# Security_group 생성
resource "aws_security_group" "allow_myweb" {
  name        = "allow_http"
  description = "allow_http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "allow_myweb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_myweb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_myweb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_myweb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# AWS EC2
resource "aws_instance" "myEC2web" {
  ami                         = "ami-0d7ae6a161c5c4239"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.allow_myweb.id]
  subnet_id                   = aws_subnet.myPubSubnet.id
  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/bin/bash
    yum -y install httpd
    echo "MyWEB" > /var/www/html/index.html
    systemctl enable --now httpd
    EOF


  tags = {
    Name = "myEc2web"
  }
}