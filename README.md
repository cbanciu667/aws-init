# aws-init - an AWS event-driven pipeline orchestrator
by B. Cosmin, 2020

# Description
This is a pipeline orchestrator based 100% on AWS and git-flow. \
By running first_time_only.sh it creates new master pipelines based on CodeBuild. \
New pipelines are created and removed with their coresponding branches (e.g. after PRs). \
To triger any pipelines  after creation one has simply to push a new commit with desired version files (semver form: x.xx.xx). \
It can be used for CI/CD pipelines for various modules like ECS, EKS, Websites, Cost Monitoring, App1, App2 \
and others. \
CloudFormation parameters for any modules except aws-init are stored in SecretsManager. \

aws-init is using CodeCommit to store its code and generate repos + pipelines for any modules. \

aws-init is building the pipelines with CodePipeline and CodeBuild. \

## This is managing:
* CodeCommit repo for itself
* CodeCommit repositories for various modules (ECS, EKS, Websites, etc.)
* CodePipeline pipelines for aws-init and other modules
* CodeBuild configuration
* AWS Secrets Manager configuration and injection mechanism
* Secrets and parameters for any projects used in the aws account

## Requirements
* git-secret
* AWS CLI configured with profiles
* AWS SAM CLI
* docker
* Python3.7
* KMS Key for Secret Manager
* jq
* updated local_env_variables
* updated version file

## Initial configuration
1. after cloning this repo run rm -rf .git to remove current git configuration

2. create AWS user in a new AWS account

3. configure AWS Cli profile based on the new user

4. create local_env_variables and fill out the values.
Example:
DEFAULT_AWS_PROFILE=MY_DEV_AWS_PROFILE
DEFAULT_AWS_REGION=eu-west-1
PROJECT_NAME=MY_PROJECT
MODULES=(ecs eks mywebsite cost-controller App1 App2 )

5. run first_time_only.sh
This will output the aws-init CodeCommit repos for all modules and generate the "master" pipelines

6. initialize git with the newly created CodeCommit repo above. DO NOT COMMIT YET!
checkout: https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html

7. install and configure git-secret
https://git-secret.io/

8. update parameters.json for the AWS Secrets Manager 
with the values required by all CloudFormation templates in modules and including aws-init.
FYI: aws-init is also considered a module
Example:
[
  {
    "MODULE_NAME-PARAMETER_NAME_1": "VALUE_1"
  }, 
  {
    "MODULE_NAME-PARAMETER_NAME_2": "VALUE_2"
  },   
  {
    "MODULE_NAME-PARAMETER_NAME_3": "VALUE_3"
  },     
  {
    "MODULE_NAME-PARAMETER_NAME_N": "VALUE_N"
  }   
]

9. add parameters.json to git secret, encrypt and decrypt once
keep the file decrypted for now

10. run ./secrets.sh create-secret

11. encrypt again parameters.json file

12. git commit on master branch

ATENTION: this will triger only generate the master pipelines 
It will not triger any module pipeline for deployments.
To triger module pipelines you need to commit and push to the specific module repo including buildspec.yml and other elements.


## Continous operation after initial configuration above
* git pull
* decrypt local_env_variables and parameters.json (ONLY IF REQUIRED)
* update local_env_variables and parameters.json if needed (ONLY IF REQUIRED)
* run ./secrets.sh update-secret (ONLY IF REQUIRED)
* update code
* change version file
* git commit
* repeat

* !IMPORTANT: 
- make sure git-secret is working properly as this is critical for operation

## How to add or remove modules
* Just add or remove the module name in the MODULES variable from local_env_variables,
commit and push new tag


## Aditional Information
The scope of this project is to demonstrate how to setup a 100% AWS CI/CD pipeline.
Similar could be easily setup in Gitlab, Jenkins or Bitbucket Pipelines but what matters here 
are the DevOps principles on which this sample project is based:

1.
All cloud formation parameters and other variables are hidden in AWS Secret Manager, 
solving the dilemma of what is a secret and what not. 
Many of the parameters used in a pipeline "could be a secret" giving hints to 
a possible attacker about your infrastructure. Therefore better be safe and obfuscate all.
Aws Secrets Manager gives you several operational advantages even when compared to 
AWS Parameter Store (e.g. loading all project secrets in one json ).

2.
Tried to parametrize everything, the only differences beying the above parameters for the 
scripts. Less values are hardcoded, the better. Optimally no parameters or variable is hardcoded.
All resource names should be dynamic and based on given parameters.

3.
Everything must be versioned and commits easy to understand. Therefore commit often, with good descriptions and a version tag.

4.
Build phase must be completely separated from deploy phase as they could be operated by separated teams at different dates.

5.
Put in place good automated cost controls and security checks. 
For flexibility a lambda running periodically for these pourposes should be ok.

Further References:
https://www.1strategy.com/blog/2019/02/28/aws-parameter-store-vs-aws-secrets-manager/
https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-https-unixes.html
https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html
https://git-secret.io/