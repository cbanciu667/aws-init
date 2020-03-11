#!/bin/bash

set -e

source local_env_variables

for MODULE in "${MODULES[@]}"
do
	aws cloudformation deploy \
    --no-fail-on-empty-changeset \
    --template-file ${MODULE}/ci-pipeline.yaml \
    --stack-name "${PROJECT_NAME}-ci-pipeline-${MODULE}-master" \
    --profile ${DEFAULT_AWS_PROFILE} \
    --region ${DEFAULT_AWS_REGION} \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameter-overrides \
      ProjectName=${PROJECT_NAME} \
      ModuleName=${MODULE} \
      BranchName="master" && 
  for STAGE in "${STAGES[@]}"
  do
    aws cloudformation deploy \
      --no-fail-on-empty-changeset \
      --template-file ${MODULE}/cd-pipeline.yaml \
      --stack-name "${PROJECT_NAME}-cd-pipeline-${MODULE}-${STAGE}" \
      --profile ${DEFAULT_AWS_PROFILE} \
      --region ${DEFAULT_AWS_REGION} \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
      --parameter-overrides \
        ProjectName=${PROJECT_NAME} \
        ModuleName=${MODULE} \
        StageName=${STAGE}
  done && 
  CI_VERSION=$(aws secretsmanager get-secret-value --secret-id ${PROJECT_NAME} --version-stage AWSCURRENT --output json --profile $DEFAULT_AWS_PROFILE | jq --raw-output '.SecretString' | jq .\"$MODULE-ci-version\" | sed 's/"//g')
  ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-ci-pipeline-${MODULE}-master --profile ${DEFAULT_AWS_PROFILE} --query "Stacks[0].Outputs[?OutputKey=='ArtifactsS3Bucket'].OutputValue" --output text) &&
  aws s3 rm --region ${DEFAULT_AWS_REGION} --profile ${DEFAULT_AWS_PROFILE} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-ci-pipeline-${CI_VERSION}.yaml &&
  aws s3 cp --region ${DEFAULT_AWS_REGION} --profile ${DEFAULT_AWS_PROFILE} ${MODULE}/ci-pipeline.yaml s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-ci-pipeline-${CI_VERSION}.yaml &&
  aws s3 rm --region ${DEFAULT_AWS_REGION} --profile ${DEFAULT_AWS_PROFILE} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-${CI_VERSION}.yaml &&
  aws s3 cp --region ${DEFAULT_AWS_REGION} --profile ${DEFAULT_AWS_PROFILE} ${MODULE}/cd-pipeline.yaml s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-${CI_VERSION}.yaml &&  
  CODE_COMMIT_REPO=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-ci-pipeline-${MODULE}-master --profile ${DEFAULT_AWS_PROFILE} --query "Stacks[0].Outputs[?OutputKey=='CodeCommitRepo'].OutputValue" --output text) &&
  echo "********* COMMIT REPO FOR MODULE >> ${MODULE} << IS:  https://git-codecommit.${DEFAULT_AWS_REGION}.amazonaws.com/v1/repos/${CODE_COMMIT_REPO}"
done