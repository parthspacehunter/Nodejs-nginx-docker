#!/bin/bash


#create our working directory if it doesnt exist
DIR="/home/ec2-user/backend-app"
if [ -d "$DIR" ]; then
  echo "${DIR} exists"
  sudo chmod -R 777 "$DIR"
  cd "$DIR"
  if [ -d "./certbot" ]; then
    mv "./certbot" "/home/ec2-user/"
  fi
else
  echo "Creating ${DIR} directory"
  mkdir ${DIR}
  sudo chmod -R 777 "$DIR"
fi
