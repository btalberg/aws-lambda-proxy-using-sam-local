#!/bin/bash

export $(cat .env | grep -v ^# | xargs)

S3_BUCKET=$1
STACK_NAME=$2

USE_MSG="Usage: deploy.sh S3_BUCKET STACK_NAME"

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "Missing AWS_ACCESS_KEY_ID ENV key"
  echo $USE_MSG
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "Missing AWS_SECRET_ACCESS_KEY ENV key"
  echo $USE_MSG
  exit 1
fi

if [ -z "$S3_BUCKET" ]; then
  echo "Missing S3_BUCKET"
  echo $USE_MSG
  exit 1
fi

if [ -z "$STACK_NAME" ]; then
  echo "Missing STACK_NAME"
  echo $USE_MSG
  exit 1
fi

# zip up function
zip api-proxy-lambda.zip index.js

# upload zip to S3
sam package \
  --template-file template.yaml \
  --s3-bucket $S3_BUCKET \
  --output-template-file package.yaml

# deploy to cloud formation
sam deploy \
  --template-file package.yaml \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_IAM

# get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[0].OutputValue')

# remove quotes
API_ENDPOINT=$(sed -e 's/^"//' -e 's/"$//' <<< $API_ENDPOINT)

echo "Test in browser: $API_ENDPOINT"
