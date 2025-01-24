#!/bin/bash
# 시스템 업데이트
yum update -y

# Apache 설치 및 시작
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# CodeDeploy Agent 설치 준비
yum install -y ruby wget

# CodeDeploy Agent 설치
cd /home/ec2-user
wget https://aws-codedeploy-${aws_region}.s3.amazonaws.com/latest/install
chmod +x ./install
./install auto

# CodeDeploy Agent 상태 확인
service codedeploy-agent status

