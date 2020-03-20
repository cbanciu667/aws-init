#!/bin/bash

set -ex

source local_env_variables

create_parameters_secret () {
  aws secretsmanager create-secret --name $PROJECT_NAME --description "Secret containing parameters for ${PROJECT_NAME}" --secret-string file://parameters.json --tags Key="scope",Value="${PROJECT_NAME}" --profile $DEFAULT_AWS_PROFILE
}

update_parameters_secret () {
  aws secretsmanager update-secret --secret-id $PROJECT_NAME --description "Secret containing parameters for ${PROJECT_NAME}" --secret-string file://parameters.json --profile $DEFAULT_AWS_PROFILE
  #for MODULE in "${MODULES[@]}"
  #do
  #  ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks --region ${DEFAULT_AWS_REGION} --profile $DEFAULT_AWS_PROFILE --stack-name ${PROJECT_NAME}-ci-pipeline-${MODULE}-master --query "Stacks[0].Outputs[?OutputKey=='ArtifactsS3Bucket'].OutputValue" --output text)
  #  for STAGE in "${STAGES[@]}"
  #  do
  #    CD_VERSION=$(aws secretsmanager get-secret-value --secret-id ${PROJECT_NAME} --version-stage AWSCURRENT --output json --profile $DEFAULT_AWS_PROFILE | jq --raw-output '.SecretString' | jq .\"$MODULE-cd-$STAGE-version\" | sed 's/"//g')
  #    aws cloudformation update-stack --stack-name ${PROJECT_NAME}-cd-pipeline-${MODULE}-${STAGE} \
  #      --template-url https://s3.eu-central-1.amazonaws.com/${ARTIFACTS_BUCKET}/templates/${MODULE}-cd-pipeline-${CD_VERSION}.yaml \
  #      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  #      --profile $DEFAULT_AWS_PROFILE \
  #      --parameters ParameterKey=ProjectName,UsePreviousValue=true ParameterKey=ModuleName,UsePreviousValue=true ParameterKey=StageName,UsePreviousValue=true ParameterKey=Version,ParameterValue=${CD_VERSION} ParameterKey=RandomParameter,ParameterValue=$RANDOM
  #  done
  #done
}

case "$1" in
  "create")
    create_parameters_secret
    ;;
  "update")
    update_parameters_secret
    ;;    
  *)
    echo "Wrong arguments. Must be one of: create or update"
    exit 1
    ;;
esac