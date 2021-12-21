# Wordpress App

## Overview

Invoked from deploy.sh and requires aws cli and docker installed on a linux commandline
(tested in ubuntu)

Master cfn script which runs nested scripts to do the following:

* It deploys a VPC, with 2 public and private subnets across 2 Availabilty Zones.
* An Internet Gateway, with a default route on the public subnets.
* 2 NAT Gateways (1 in each AZ) and default routes for them in the private subnets.
* A highly available ECS cluster using an AutoScaling Group, with ECS hosts distributed across 2 Availability Zones.
* A Multi-AZ RDS

* Pulls a docker image (wordpress) and pushes it to ecr
* Gets the database endpoint URL from the above RDS and sets this in the servicee
* Deploys a service for the ECS cluster which pulls the docker image from ecr

### How to use it

1. Install aws cli and docker and configure aws credentials or run on instance that has required permissions
2. In the deploy.sh script at the top where it says 'set env variables (to change)' set these for your region, aws_account_id and s3_bucket_name (must be unique) which you wish to create to your account
3. Run deploy.sh
4. The main stack should output the url to access the website
