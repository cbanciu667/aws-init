#!/bin/bash

set -e

source env_variables

ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-ci-pipeline-${MODULE}-master --query "Stacks[0].Outputs[?OutputKey=='ArtifactsS3Bucket'].OutputValue" --output text)
CI_VERSION=$(aws secretsmanager get-secret-value --secret-id ${PROJECT_NAME} --version-stage AWSCURRENT --output json | jq --raw-output '.SecretString' | jq .\"$MODULE-ci-version\" | sed 's/"//g')
zip -r ${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip ./*
aws s3 rm --region ${DEFAULT_AWS_REGION} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip
aws s3 cp --region ${DEFAULT_AWS_REGION} ${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-artifact-${CI_VERSION}.zip