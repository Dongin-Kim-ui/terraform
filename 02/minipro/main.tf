##################################
# 기본 인프라 구성
##################################
# 1. VPC 설정
# 2. Internet Gateway 생성 및 연결
# 3. Public subnet 설정
# 4. Public Routing 생성 및 연결
##################################
# EC2 인스턴스 생성
##################################
# 1. Public Security Group 설정
# 2. AMI Data Source 설정
# 3. SSH Key 생성
# 4. EC2 Instance 생성


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.83.1"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}
##################################
#기본 인프라 구성
##################################
# 1. VPC 설정
# Resource: aws_vpc
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
# * enable_dns_hostnames = true
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}

# 2. Internet Gateway 설정
# Resource: aws_internet_gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

# 3. Public subnet 설정
# Resource: aws_subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# * map_public_ip_on_launch = true << 서브넷 생성할 때 퍼블릭 IPv4 주소 자동 할당 (예)
# * availability_zone   가용 영역 설정

resource "aws_subnet" "mypubSN" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.123.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSN"
  }
}

# 4. Public Routing 설정
# Resource: aws_route_table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
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


# 5. Public Routing Table Association
# Resource: aws_route_table_association
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.mypubSN.id
  route_table_id = aws_route_table.myPubRT.id
}
##################################
# EC2 인스턴스 생성
##################################
# 1. Public Security Group 설정
# Resource: aws_security_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
# 2. SSH Key 생성
# Resource: aws_key_pair
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# 3. AMI Data Source 설정
# Resource: aws_instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
data "aws_ami" "ubuntu2204" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# 4. EC2 Instance 생성
# Resource: aws_instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "myDevServer" {
  ami                         = data.aws_ami.ubuntu2204.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.mykeypair.id
  subnet_id                   = aws_subnet.mypubSN.id
  security_groups             = [aws_security_group.mySG.id]
  user_data_replace_on_change = true
  user_data                   = file("userdata.tpl")
  provisioner "local-exec" {
    command = templatefile("ssh-config.tpl", {
      hostname     = self.public_ip,
      identifyfile = "~/.ssh/id_ed25519",
      username     = "ubuntu",
    })
    interpreter = ["bash", "-c"]
  }

  tags = {
    Name = "myDevServer"
  }
}