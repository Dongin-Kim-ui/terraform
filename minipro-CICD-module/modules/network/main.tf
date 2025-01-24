resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "Allow SSH,HTTP inbound traffic and all outbound traffic"

  tags = {
    Name = "mysg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4        = "0.0.0.0/0"
  from_port        = 22
  ip_protocol      = "tcp"
  to_port          = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4        = "0.0.0.0/0"
  from_port        = 80
  ip_protocol      = "tcp"
  to_port          = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4        = "0.0.0.0/0"
  ip_protocol      = "-1"
}