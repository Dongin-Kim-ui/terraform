# Provider 설정
provider "aws" {
  region = "us-east-2"
}

# EC2 인스턴스 AMI ID를 위한 Data Source 조회
# * Amazon Linux 2023 AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}


# 보안 그룹
# ssh(22/tcp) 
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_instance" "myEC2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

# Keypair 지정
# - keypair 이름 : mykeypair2
  key_name = "mykeypair2"
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "myEC2"
  }
}

output "ami_id" {
    value = aws_instance.myEC2.ami
    description = "Ubuntu 24.04 LTS AMI ID"
}
