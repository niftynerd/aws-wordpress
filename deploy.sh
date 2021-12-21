#!/bin/bash

# set env variables (to change)
region=ap-southeast-2
aws_account_id=300762679816
s3_bucket_name=test-1337

# other variables
DbUser=iamauser
DbPassword=changeme
DbName=mydb

# create s3 bucket for cloudformation templates
aws s3api create-bucket --bucket $s3_bucket_name --region ${region} --create-bucket-configuration LocationConstraint=${region}

# copy cfn files to s3
aws s3 cp cfn s3://${s3_bucket_name}/ --recursive

# deploy cfn stack
aws cloudformation deploy --template-file cfn/all.yaml --stack-name test-stack --parameter-overrides S3BucketName=${s3_bucket_name} Region=${region} DbUser=${DbUser} DbPassword=${DbPassword} DBName=${DbName} --capabilities CAPABILITY_NAMED_IAM

# get rds endpoint url and append to conf file
endpoint_url=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'RDS\'].OutputValue --output text`

# build docker image
imageToPull=wordpress
imageName=test/${imageToPull}
docker pull ${imageToPull}

# create ecr repo for docker image
aws ecr create-repository --repository-name $imageName

# push docker image to ecr repo
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${region}.amazonaws.com

image=${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${imageName}:latest
docker tag ${imageToPull}:latest ${image}
docker push ${image}

# create service from pushed docker image
ContainerPort=80
VPC=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'VPC\'].OutputValue --output text`
Cluster=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'Cluster\'].OutputValue --output text`
Listener=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'Listener\'].OutputValue --output text`
ECSServiceAutoScalingRoleARN=`aws cloudformation describe-stacks --query Stacks[].Outputs[?OutputKey==\'ECSServiceAutoScalingRole\'].OutputValue --output text`
DesiredCount=2

aws cloudformation deploy --template-file cfn/service.yaml --stack-name service-stack --parameter-overrides VPC=${VPC} Cluster=${Cluster} DesiredCount=${DesiredCount} Listener=${Listener} ECSServiceAutoScalingRoleARN=${ECSServiceAutoScalingRoleARN} Image=${image} ContainerPort=${ContainerPort} DbEndpoint=${endpoint_url} DbUser=${DbUser} DbPassword=${DbPassword} DbName=${DbName} --capabilities CAPABILITY_NAMED_IAM
