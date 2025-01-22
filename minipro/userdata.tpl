#!/bin/bash
curl -fsSL https://test.docker.com -o test-docker.sh
sudo sh test-docker.sh
sudo systemctl enable --now docker

