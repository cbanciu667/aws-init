#!/bin/bash

set -e

source env_variables

ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-ci-pipeline-${MODULE}-master --query "Stacks[0].Outputs[?OutputKey=='ArtifactsS3Bucket'].OutputValue" --output text)
CI_VERSION=$(aws secretsmanager get-secret-value --secret-id ${PROJECT_NAME} --version-stage AWSCURRENT --output json | jq --raw-output '.SecretString' | jq .\"$MODULE-ci-version\" | sed 's/"//g')
aws s3 ls --region ${DEFAULT_AWS_REGION} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip

for STAGE in "${STAGES[@]}"
do
  aws cloudformation update-stack --stack-name ${PROJECT_NAME}-cd-pipeline-${MODULE}-${STAGE} \
    --use-previous-template --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameters ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} ParameterKey=ModuleName,ParameterValue=${MODULE} ParameterKey=StageName,ParameterValue=${STAGE} ParameterKey=Version,ParameterValue=${CI_VERSION} ParameterKey=RandomParameter,ParameterValue=$RANDOM
done