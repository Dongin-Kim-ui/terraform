# provider 설정
provider "aws" {
  region = "us-east-2"
}

# SG 생성 - 8080
resource "aws_security_group" "allow_8080" {
  name        = var.security_group_name
  description = "Allow 8080 inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_8080"
  }
}




# SG ingress(인바운드) rule
resource "aws_vpc_security_group_ingress_rule" "allow_http_8080" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.server_port
  ip_protocol       = "tcp"
  to_port           = var.server_port
}


# SG egress(아웃바운드) rule
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


# EC2 생성
resource "aws_instance" "myweb" {
  ami           = "ami-036841078a4b68e14"
  instance_type = "t2.micro"


vpc_security_group_ids = [aws_security_group.allow_8080.id]

user_data_replace_on_change = true
user_data = <<-EOF
    #!/bin/bash
    echo "Hello world" > index.html
    nohup busybox httpd -f -p 8080 &
    EOF


  tags = {
    Name = "myweb"
  }
}
