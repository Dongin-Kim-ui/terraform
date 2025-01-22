# VPC 생성
# IGW 생성 및 연결
# Public Subnet 생성
# Public Routing Table 생성
# Public Routing Table에 Default Route 설정


# 1.  VPC 생성
# Resource: aws_vpc
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "MyVPC" {
  cidr_block = var.vpc_id
  tags = var.vpc_tag
}

# 2. IGW 생성 및 연결
# Resource: aws_internet_gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.MyVPC.id

  tags = var.igw_tag
}

# 3. Public Subnet 생성
# Resource: aws_subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "mysubnet" {
  vpc_id     = aws_vpc.MyVPC.id
  cidr_block = var.subnet_cidr
  availability_zone = "ap-northeast-2c"

  tags = var.subnet_tag
}

# 4. Public Routing Table 생성
# Resource: aws_route_table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "mypubtable" {
  vpc_id = aws_vpc.MyVPC.id
  tags   = var.routetable_tag

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
}

resource "aws_route_table_association" "myassoc" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.mypubtable.id
}

# Security Group 설정

resource "aws_security_group" "mysg" {
  name        = "allow web"
  description = "Allow HTTP/HTTPS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.MyVPC.id

  tags = var.mysg_tag
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}