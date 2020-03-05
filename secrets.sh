#!/bin/bash

source local_env_parameters

create_parameters_secret () {
  aws secretsmanager create-secret --name $PROJECT_NAME --description "Secret containing parameters for ${PROJECT_NAME}" --secret-string file://parameters.json --tags Key="Scope",Value="${PROJECT_NAME}" --profile $DEFAULT_AWS_PROFILE
}

update_parameters_secret () {
  aws secretsmanager update-secret --secret-id $PROJECT_NAME --description "Secret containing parameters for ${PROJECT_NAME}" --secret-string file://parameters.json --profile $DEFAULT_AWS_PROFILE
}

case "$4" in
  "create-secret")
    create_parameters_secret
    ;;
  "update-secret")
    update_parameters_secret
    ;;    
  *)
    echo "Wrong arguments. Must be one of: create-secret, update-secret"
    exit 1
    ;;
esac