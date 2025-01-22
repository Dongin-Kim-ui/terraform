# Resource: aws_instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

data "aws_ami" "myubuntu2024" {
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



resource "aws_instance" "myec2" {
  ami           = data.aws_ami.myubuntu2024.id
  instance_type = var.instance_type
  user_data = file("./userdata.sh")

  # 필수 입력 사항
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids = var.sg_ids
  key_name = var.keypair
  tags                        = var.ec2tag

}

