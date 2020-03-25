#!/bin/bash

set -ex

source local_env_variables

create_parameters_secret () {
  aws secretsmanager create-secret --name $PROJECT_NAME --description "Secret containing parameters for ${PROJECT_NAME}" --secret-string file://parameters.json --tags Key="scope",Value="${PROJECT_NAME}" --profile $DEFAULT_AWS_PROFILE
}

update_parameters_secret () {
  aws secretsmanager update-secret --secret-id $PROJECT_NAME --description "Secret containing parameters for ${PROJECT_NAME}" --secret-string file://parameters.json --profile $DEFAULT_AWS_PROFILE
}

update_cd () {
  for MODULE in "${MODULES[@]}"
  do
    for STAGE in "${STAGES[@]}"
    do
      CD_VERSION=$(aws secretsmanager get-secret-value --secret-id ${PROJECT_NAME} --version-stage AWSCURRENT --output json --profile $DEFAULT_AWS_PROFILE | jq --raw-output '.SecretString' | jq .\"$MODULE-cd-$STAGE-version\" | sed 's/"//g')
      aws cloudformation update-stack --stack-name ${PROJECT_NAME}-cd-pipeline-${MODULE}-${STAGE} \
        --use-previous-template --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        --profile $DEFAULT_AWS_PROFILE \
        --parameters ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} ParameterKey=ModuleName,ParameterValue=${MODULE} ParameterKey=StageName,ParameterValue=${STAGE} ParameterKey=Version,ParameterValue=${CD_VERSION} ParameterKey=RandomParameter,ParameterValue=$RANDOM
    done
  done
}

case "$1" in
  "create")
    create_parameters_secret
    ;;
  "update")
    update_parameters_secret
    ;;    
  "update-cd")
    update_cd
    ;;      
  *)
    echo "Wrong arguments. Must be one of: create, update or update-cd"
    exit 1
    ;;
esac