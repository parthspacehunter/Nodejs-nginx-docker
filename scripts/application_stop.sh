#!/bin/bash
#Stopping existing node servers
echo "Stopping any existing backend servers"
cd /home/ec2-user/backend-app
docker-compose down