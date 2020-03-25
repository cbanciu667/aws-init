#!/bin/bash

set -e

source env_variables

ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-ci-pipeline-aws-init-master --query "Stacks[0].Outputs[?OutputKey=='ArtifactsS3Bucket'].OutputValue" --output text)
CI_VERSION=$(aws secretsmanager get-secret-value --secret-id ${PROJECT_NAME} --version-stage AWSCURRENT --output json | jq --raw-output '.SecretString' | jq '."aws-init-ci-version"' | sed 's/"//g')


for MODULE in "${MODULES[@]}"
do
  zip -r ${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip ${MODULE}/*
  aws s3 rm --region ${DEFAULT_AWS_REGION} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip
  aws s3 rm --region ${DEFAULT_AWS_REGION} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-ci-pipeline-${CI_VERSION}.yaml  
  aws s3 rm --region ${DEFAULT_AWS_REGION} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-${CI_VERSION}.yaml
  aws s3 cp --region ${DEFAULT_AWS_REGION} ${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip
  aws s3 cp --region ${DEFAULT_AWS_REGION} ${MODULE}/ci-pipeline.yaml s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-ci-pipeline-${CI_VERSION}.yaml
  aws s3 cp --region ${DEFAULT_AWS_REGION} ${MODULE}/cd-pipeline.yaml s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-${CI_VERSION}.yaml
done

# adding the SMR (Service Manager Requester) lambda to get secrets into CF templates. 
# At the moment querying secrets from SM is unstable for some resources and is imposible to use with 3 layers intrinsec functions
pip3 install --upgrade pip
pip3 install -r aws-init/code/secrets-manager-requester/requirements.txt -t aws-init/code/secrets-manager-requester/
aws cloudformation package --template-file aws-init/smr.yaml --s3-bucket ${ARTIFACTS_BUCKET} --output-template-file aws-init/smr-output.yaml
aws cloudformation validate-template --template-body file://aws-init/smr-output.yaml
aws cloudformation deploy --template-file aws-init/smr-output.yaml --stack-name ${PROJECT_NAME}-SMR-lambda --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM