#!/bin/bash
sudo apt install -y apache2 ssl-cert
sudo systemctl enable --now apache2
echo "MyWEB Page" > /var/www/html/index.html

