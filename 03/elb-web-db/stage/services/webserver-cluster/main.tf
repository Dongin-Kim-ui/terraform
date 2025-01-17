# Provider
provider "aws" {
  region = "us-east-2"

}

# 작업 절차
# 1. Basic Infrastructure 구성      
# Default VPC                      
# Default Subnets              
# 2. ALB + TG(ASG, EC2 x 2)  
# 2-1. ASG                     
# - SG                
# - Launch Template     
# - ASG             
# 2-2. ALB + TG 구성
# - SG
# - TG(Target Group)
# - ALB
#   - LB
#   - Listener
#   - Listener Rule
#   - Target Group


#################################
# 1. Basic Infrastructure 구성     
################################# 
# Default VPC                  
# Data Source: aws_vpc
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpc" "default" {
  default = true
}

# Default Subnets           
# Data Source: aws_subnets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#################################   
# 2. ALB + TG(ASG, EC2 x 2)  
#################################
# 2-1. ASG                     
# - SG(Security Group)
# * ingress : 8080/tcp
# * egress : all traffic
resource "aws_security_group" "myasg_8080" {
  name        = "allow_tls"
  description = "Allow 8080 inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myasg_8080"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_22" {
  security_group_id = aws_security_group.myasg_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_8080" {
  security_group_id = aws_security_group.myasg_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.myasg_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# - Launch Template     
# Resource: aws_launch_template
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
data "aws_ami" "ubuntu2404" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "terraform_remote_state" "myTFstate" {
  backend = "s3"
  config = {
    bucket = "bucket-2002-0307"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-2"
  }
}

resource "aws_launch_template" "MyLT" {
  name = "myLT"
  # Ubuntu 24.04 LTS
  image_id               = data.aws_ami.ubuntu2404.id
  instance_type          = "t2.micro"
  key_name               = "mykeypair2"
  vpc_security_group_ids = [aws_security_group.myasg_8080.id]
  user_data = base64encode(templatefile("user-data.sh", {
    db_address  = data.terraform_remote_state.myTFstate.outputs.address,
    db_port     = data.terraform_remote_state.myTFstate.outputs.port,
    server_port = 8080
  }))

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "test"
    }
  }
}

# - TG + ASG        
# Resource: aws_lb_target_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "myalb-tg" {
  name     = "myalb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}


# Resource: aws_autoscaling_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
# (주의) target_group_arns 필요
resource "aws_autoscaling_group" "myasg" {
  name = "myasg"

  min_size = 2
  max_size = 10

  health_check_grace_period = 300
  health_check_type         = "ELB"

  desired_capacity = 2
  force_delete     = true
  #-------------------[warning]----------------------------
  target_group_arns = [aws_lb_target_group.myalb-tg.arn]
  depends_on        = [aws_lb_target_group.myalb-tg]
  #----------------------------------------------------------

  launch_template {
    id      = aws_launch_template.MyLT.id
    version = aws_launch_template.MyLT.latest_version
  }
  vpc_zone_identifier = data.aws_subnets.default.ids


  tag {
    key                 = "Name"
    value               = "myasg"
    propagate_at_launch = true
  }
}
# 2-2. ALB + TG 구성
# - SG
resource "aws_security_group" "myalb_80" {
  name        = "myalb_80"
  description = "Allow 80 inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myalb_80"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.myalb_80.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}



resource "aws_vpc_security_group_egress_rule" "allow_myalb_all" {
  security_group_id = aws_security_group.myalb_80.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
# - TG(Target Group)  => 미리 구성됌
# - ALB
#   - LB   ALB LB 같다.
# Resource: aws_lb
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false

  load_balancer_type = "application"
  security_groups    = [aws_security_group.myalb_80.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Environment = "myalb"
  }
}
#   - Listener  (aws_alb_listener is known as aws_lb_listener)
# Resource: aws_lb_listener
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "myalb_listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myalb-tg.arn
  }
}
#   - Listener Rule ==> default_action으로 처리됌
#   - Target Group

