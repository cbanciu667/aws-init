#!/bin/bash

set -e

source local_env_variables

VERSION=$(cut -d "_" -f 2 <<< $(ls version_*))

for MODULE in "${MODULES[@]}"
do
	aws cloudformation deploy \
    --no-fail-on-empty-changeset \
    --template-file pipeline.yaml \
    --stack-name "${PROJECT_NAME}-pipeline-${MODULE}-prod" \
    --profile ${DEFAULT_AWS_PROFILE} \
    --region ${DEFAULT_AWS_REGION} \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameter-overrides \
      ProjectName=${PROJECT_NAME} \
      ModuleName=${MODULE} \
      Version=${VERSION} \
      BranchName="master" && 
  ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-pipeline-${MODULE}-prod --profile ${DEFAULT_AWS_PROFILE} --query "Stacks[0].Outputs[?OutputKey=='ArtifactsS3Bucket'].OutputValue" --output text) &&
  aws s3 rm --region ${DEFAULT_AWS_REGION} --profile ${DEFAULT_AWS_PROFILE} s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-pipeline-${VERSION}.yaml &&
  aws s3 cp --region ${DEFAULT_AWS_REGION} --profile ${DEFAULT_AWS_PROFILE} pipeline.yaml s3://${ARTIFACTS_BUCKET}/templates/${MODULE}-pipeline-${VERSION}.yaml &&
  CODE_COMMIT_REPO=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --stack-name ${PROJECT_NAME}-pipeline-${MODULE}-prod --profile ${DEFAULT_AWS_PROFILE} --query "Stacks[0].Outputs[?OutputKey=='CodeCommitRepo'].OutputValue" --output text) &&
  echo "********* COMMIT REPO FOR MODULE >> ${MODULE} << IS:  https://git-codecommit.${DEFAULT_AWS_REGION}.amazonaws.com/v1/repos/${CODE_COMMIT_REPO}"
done

#aws secretsmanager create-secret --name "${PROJECT_NAME}" \
#    --description "Secret containing parameters for ${PROJECT_NAME}" \
#    --secret-string file://parameters.json \
#    --tags Key="scope",Value="${PROJECT_NAME}" \
#    --profile ${DEFAULT_AWS_PROFILE}