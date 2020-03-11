#!/bin/bash

set -e

source env_variables

for MODULE in "${MODULES[@]}"
do
  aws cloudformation validate-template --template-body file://${MODULE}/ci-pipeline.yaml
  aws cloudformation validate-template --template-body file://${MODULE}/cd-pipeline.yaml
done