#!/bin/bash
set -e

ENVIRONMENT=$1
APPLICATION_NAME=$2
echo "Getting Secrets from SSM...."
DB_HOST=$(aws ssm get-parameter --with-decryption --name "/nonprod/rds/mysql/host" --query "Parameter.Value" --output text)
DB_USERNAME=$(aws ssm get-parameter --with-decryption --name "/$ENVIRONMENT/$APPLICATION_NAME/DB_USERNAME" --query "Parameter.Value" --output text)
DB_PASSWORD=$(aws ssm get-parameter --with-decryption --name "/$ENVIRONMENT/$APPLICATION_NAME/DB_PASSWORD" --query "Parameter.Value" --output text)
echo "Creating Bastion Pod...."
kubectl run "bastion-$RANDOM" --rm -it --image alpine --env="DB_HOST=$DB_HOST" --env="DB_USERNAME=$DB_USERNAME" --env="DB_PASSWORD=$DB_PASSWORD" -- sh -c 'apk add mysql-client && mysql -h$DB_HOST -u$DB_USERNAME -p$DB_PASSWORD'
