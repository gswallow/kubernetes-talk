#!/bin/bash -e

date=$(date '+%Y%m%d%H%M')
aws cloudformation create-stack --stack-name ${org}-buckets-${AWS_REGION}-${date} --template-body file://buckets.json
aws cloudformation create-stack --stack-name ${org}-vpc-${AWS_REGION}-${date} --template-body file://vpc.json
