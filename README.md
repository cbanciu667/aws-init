# aws-init - Ci/Cd AWS event-driven pipeline orchestrator
by B. Cosmin, 2020

# Description
This is a pipeline orchestrator based 100% on AWS and git-flow. \
By running first_time_only.sh it creates new master pipelines based on CodeBuild. \
New Ci pipelines are created and removed based on their coresponding branches (e.g. after PRs). \
To triger the Ci pipelines after creation, update parameters.json, run secrets.sh update and 
push a new commit with desired version files (semver form: x.xx.xx). \
It can be used for CI/CD pipelines for various modules like ECS, EKS, Websites, Cost Monitoring, App1, App2 etc. \
All CloudFormation parameters for any modules (except partially for aws-init) are stored in SecretsManager. \

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
DEFAULT_AWS_PROFILE=MY_AWS_CLI_PROFILE
DEFAULT_AWS_REGION=eu-west-1
PROJECT_NAME=MY_PROJECT
MODULES=( aws-init ecs App1 App2 )
STAGES=( dev int prod )

5. clone this to env_variables but without containing DEFAULT_AWS_PROFILE

6. update parameters.json for the AWS Secrets Manager 
with the values required by all CloudFormation templates in modules and including aws-init.
FYI: aws-init is also considered a module
Example:
{
  "aws-init-ci-version": "1.0.0",
  "ecs-ci-version": "1.0.0",
  "aws-init-cd-dev-version": "1.0.0",
  "aws-init-cd-int-version": "1.0.0",
  "aws-init-cd-prod-version": "1.0.0",
  "ecs-cd-dev-version": "1.0.0",
  "ecs-cd-int-version": "1.0.0",
  "ecs-cd-prod-version": "1.0.0"
}

7. run ./secrets.sh create

8. run first_time_only.sh
This will output the aws-init CodeCommit repos for all modules and generate the initial Ci/Cd pipelines

9. initialize git with the newly created CodeCommit repo above. DO NOT COMMIT YET!
checkout: https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html

10. install and configure git-secret
https://git-secret.io/

11. encrypt again parameters.json file

12. git commit on master branch

ATENTION: this will triger only generate the master pipelines
It will not triger any module pipeline for deployments.
To triger module pipelines you need to commit and push to the specific module repo including buildspec.yml and other elements.


## Continous operation after initial configuration above
* git pull
* decrypt local_env_variables and parameters.json (ONLY IF REQUIRED)
* update env_variables or ci version in parameters.json if needed (ONLY IF REQUIRED)
* run ./secrets.sh update (ONLY IF REQUIRED)
* encrypt parameters.json
* commit to trigger the ci pipeline
* change cd version in paramters.json for desired environment
* trigger cd pipeline in code pipeline
* repeat

* !IMPORTANT: 
- make sure git-secret is working properly as this is critical for operation

## How to add or remove modules and stages
* Just add or remove the module names and stages in the MODULES/STAGES variables from env_variables,
commit and push

## Planned improvments
* Refactored permissions for all IAM Roles used
* Automated git tagging corelated with versions from SecretsManager
or switching to commit ID strategy
* Adding modules like cost-controller, ecs and eks


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
Everything must be versioned and commits easy to understand. Therefore commit often, with good descriptions and versioned artifacts.

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