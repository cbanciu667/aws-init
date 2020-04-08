#!/bin/bash

source env_variables

STAGE_NAME=$1

# get the current pipeline artifacts bucket
ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-ci-pipeline-${MODULE}-master --query "Stacks[0].Outputs[?OutputKey=='ArtifactsS3Bucket'].OutputValue" --output text)
# deploy serverless stack with SAM
sam deploy --stack-name ${PROJECT_NAME}-${MODULE}-${STAGE_NAME} --s3-bucket ${ARTIFACTS_BUCKET} --region ${DEFAULT_AWS_REGION} --no-fail-on-empty-changeset --template-file website.yaml --capabilities CAPABILITY_IAM --parameter-overrides ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} ParameterKey=ModuleName,ParameterValue=${MODULE} ParameterKey=StageName,ParameterValue=${STAGE_NAME}
# get website s3 bucket
WEBSITE_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-${MODULE}-${STAGE_NAME} --query "Stacks[0].Outputs[?OutputKey=='WebsiteS3Bucket'].OutputValue" --output text)
# sync static content
aws s3 sync static_code s3://${WEBSITE_BUCKET} --region ${DEFAULT_AWS_REGION} --acl public-read

#if aws s3 ls "s3://${PROJECT_NAME}-${MODULE}-public" 2>&1 | grep -q 'NoSuchBucket'
#then
#else
#fi