# aws-init - Ci/Cd AWS event-driven pipeline orchestrator
by B. Cosmin, 2020

# Description
This is a pipeline orchestrator based 100% on AWS and git-flow. \
By running first_time_only.sh it creates new master pipelines based on CodeBuild. \
New Ci pipelines are created and removed based on their coresponding branches (e.g. after PRs). \
To triger the Ci pipelines after creation, update parameters.json, run secrets.sh with \
update parameter and push a new commit. Ci pipeline will produce new artifacts that are stored in S3. \
This can be extended for CI/CD pipelines for various modules like ECS, EKS, Websites, Cost Monitoring, App1, App2 etc. \
All CloudFormation parameters for any modules (except partially for aws-init) are stored in SecretsManager.

aws-init is using CodeCommit to store its code and generate repos + CD pipelines for any modules.

aws-init is building the CD pipelines with CodePipeline and CodeBuild.

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
* git-remote-codecommit helper
* KMS Key for Secret Manager
* jq
* updated local_env_variables and cloned to env_variables
* updated parameters.json into SecretsManager

## Initial configuration
1. after cloning this repo run rm -rf .git to remove current git configuration

2. create AWS user in a new AWS account

3. configure AWS Cli profile based on the new user

4. create local_env_variables and fill out the values.
Example:\
DEFAULT_AWS_PROFILE=MY_AWS_CLI_PROFILE\
DEFAULT_AWS_REGION=eu-west-1\
PROJECT_NAME=MY_PROJECT\
MODULES=( aws-init ecs App1 App2 )\
STAGES=( dev int prod )

5. clone this to env_variables but without containing DEFAULT_AWS_PROFILE

6. update parameters.json for the AWS Secrets Manager\
with the values required by all CloudFormation templates in modules and including aws-init.\
FYI: aws-init is also considered a module\
Example:\
{\
  "aws-init-ci-version": "1.0.0",\
  "aws-init-cd-dev-version": "1.0.0",\
  "aws-init-cd-int-version": "1.0.0",\
  "aws-init-cd-prod-version": "1.0.0",\
  "ecs-cd-dev-version": "1.0.0",\
  "ecs-cd-int-version": "1.0.0",\
  "ecs-cd-prod-version": "1.0.0"\
  "route53-cd-dev-version": "1.0.0",\
  "route53-cd-int-version": "1.0.0",\
  "route53-cd-prod-version": "1.0.0",\  
  "route53-domain-name": "domain.com"\    
}

7. run ./secrets.sh create

8. run first_time_only.sh
This will output the aws-init CodeCommit repos for all modules and generate the initial Ci/Cd pipelines

9. initialize git with the newly created CodeCommit repo above. DO NOT COMMIT YET!\
checkout: https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html

10. install and configure git-secret\
https://git-secret.io/

11. encrypt again parameters.json file

12. git commit on master branch

ATENTION: this will triger only generate the master pipelinesand it will not triger any module pipeline for deployments.\
To triger module pipelines you need to commit and push to the specific module repo including buildspec.yml and other elements.


## Continous operation after initial configuration above
* git pull
* decrypt local_env_variables and parameters.json (ONLY IF REQUIRED)
* update env_variables or ci version in parameters.json 
(FROM NOW ON you will work with env_variables file and NOT local_env_variables)
* run ./secrets.sh update
* encrypt parameters.json
* commit to trigger the ci pipeline
* change cd version in paramters.json for desired environment
* trigger cd pipeline in code pipeline
* repeat

* IMPORTANT: 
make sure git-secret is working properly as this is critical for operation!\
AWS-INIT modules is made only to orchestrate the CI/CD pipelines and manage,\
all the CF parameters via secrets, the rest is handled via code from the modules CodeCommit repos!\
Be aware for the namming convention everywhere!

## How to add or remove modules and stages
Just add the module names and stages in the MODULES & STAGES\
variables from local_env_variables, update SecretsManager with parameters.json,\
run again first_time_omly.sh (First time only = first time for new mosuled & stages).\
commit and push the new aws-init configuration.

After that step used the output of first_time_omly.sh to add the repos for the modules.\
For each module copy in its repo and commit the aws ./aws-init configuration.\
Adapt it and use it for that module.

## Planned improvments in Q2 2020
* Delete features for pipelines
* Automated git tagging corelated with versions from SecretsManager
* Permission Boundaries
* Adding modules like cost-controller, eks, IoT

## Aditional Information
The scope of this project is to demonstrate how to setup a 100% AWS CI/CD pipeline.\
Similar could be easily setup in Gitlab, Jenkins or Bitbucket Pipelines but what matters here\
are the DevOps principles on which this sample project is based:

Most cloud formation parameters and other variables are hidden in AWS Secret Manager,\
solving the dilemma of what is a secret and what not.\
Many of the parameters used in a pipeline "could be a secret" giving hints to\
a possible attacker about your infrastructure. Therefore better be safe and obfuscate almost all.\
Aws Secrets Manager gives you several operational advantages even when compared to\
AWS Parameter Store (e.g. loading all project secrets in one json ).

Tried to parametrize everything, the only differences beying the above parameters for the\
scripts. Less values are hardcoded, the better. Optimally no parameters or variable is hardcoded.\
All resource names should be dynamic and based on given parameters.

Everything must be versioned and commits easy to understand. Therefore commit often,\
with good descriptions and versioned artifacts.

Build phase must be completely separated from deploy phase as they could be operated by separated teams at different dates.

Put in place good automated cost controls and security checks.\
For flexibility a lambda running periodically for these pourposes should be ok.

## Further References:
https://www.1strategy.com/blog/2019/02/28/aws-parameter-store-vs-aws-secrets-manager/
https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-https-unixes.html
https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html
https://github.com/aws/git-remote-codecommit
https://git-secret.io/
https://12factor.net/