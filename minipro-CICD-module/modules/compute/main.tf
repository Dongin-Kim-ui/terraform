data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "myEC2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name              = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile

  user_data = templatefile("${path.module}/user_data.sh", {
    aws_region = var.aws_region
  })

  tags = {
    Name = "myEC2"
  }
}