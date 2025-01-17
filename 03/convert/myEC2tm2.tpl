#!/bin/bash
hostname ELB-EC2-2
yum install httpd -y
service httpd start
chkconfig httpd on
echo "<h1>CloudNet@ EC2-2 Web Server</h1>" > /var/www/html/index.html