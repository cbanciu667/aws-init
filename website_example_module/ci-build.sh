#!/bin/bash

set -e
# get base variables required for the ci pipeline
source env_variables
# get the current pipeline artifacts bucket
ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-ci-pipeline-${MODULE}-master --query "Stacks[0].Outputs[?OutputKey=='ArtifactsS3Bucket'].OutputValue" --output text)
# get the desired version from SecretsManager
CI_VERSION=$(aws secretsmanager get-secret-value --secret-id ${PROJECT_NAME} --version-stage AWSCURRENT --output json | jq --raw-output '.SecretString' | jq .\"$MODULE-ci-version\" | sed 's/"//g')
# build the CloudFormation artifact
sam build -m lambda_code/requirements.txt -t website.yaml --region ${DEFAULT_AWS_REGION}
# switch to cd buildspec for archival of the artefact
mv buildspec.yaml buildspec-ci.yaml
mv buildspec-cd.yaml buildspec.yaml
# archive artefact with desired version
zip -r ${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip ./*
# switch to ci buildspec again to continue with current pipeline
mv buildspec.yaml buildspec-cd.yaml
mv buildspec-ci.yaml buildspec.yaml
# cleanup previous artifact
aws s3 rm --region ${DEFAULT_AWS_REGION} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip
# push new artifact to s3 for the cd pipeline
aws s3 cp --region ${DEFAULT_AWS_REGION} ${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip