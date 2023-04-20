#!/bin/bash

#give permission for everything in the express-app directory
sudo chmod -R 777 /home/ec2-user/backend-app

#navigate into our working directory where we have all our github files
cd /home/ec2-user/
if [ -d "./certbot" ]; then
    mv "./certbot" "/home/ec2-user/backend-app"
fi
cd /home/ec2-user/tk-api/
#start containers
./init-letsencrypt.sh