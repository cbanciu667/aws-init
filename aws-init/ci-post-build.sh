#!/bin/bash

set -e

source env_variables

for MODULE in "${MODULES[@]}"
do
  ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-ci-pipeline-aws-init-master --query "Stacks[0].Outputs[?OutputKey=='ArtifactsS3Bucket'].OutputValue" --output text)
  CI_VERSION=$(aws secretsmanager get-secret-value --secret-id ${PROJECT_NAME} --version-stage AWSCURRENT --output json | jq --raw-output '.SecretString' | jq '."aws-init-ci-version"' | sed 's/"//g')
  aws s3 ls --region ${DEFAULT_AWS_REGION} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-ci-pipeline-${CI_VERSION}.yaml
  aws s3 ls --region ${DEFAULT_AWS_REGION} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-${CI_VERSION}.yaml
  aws s3 ls --region ${DEFAULT_AWS_REGION} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip
  for STAGE in "${STAGES[@]}"
  do
    aws cloudformation update-stack --stack-name ${PROJECT_NAME}-cd-pipeline-${MODULE}-${STAGE} \
      --template-url https://s3.amazonaws.com/${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-${CI_VERSION}.yaml \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
      --parameters ParameterKey=ProjectName,UsePreviousValue=true ParameterKey=ModuleName,UsePreviousValue=true ParameterKey=StageName,UsePreviousValue=true ParameterKey=Version,ParameterValue=${CI_VERSION} ParameterKey=RandomParameter,ParameterValue=$RANDOM
  done
done