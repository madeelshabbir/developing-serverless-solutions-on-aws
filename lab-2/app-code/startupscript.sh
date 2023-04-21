#!/bin/bash
# Task 0: Resize volume
sh resize.sh 20
# Task 1: validate and install package
sam --version
sudo yum -y install jq
# unzip source code
# unzip app-code.zip
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set
aws configure set default.region ${AWS_REGION}
aws configure get default.region
# Task 2: modify ./backend/src/samconfig.toml file
export LambdaRoleName=LambdaDeploymentRole
export Lambda_Role_ARN=$(aws iam get-role --role-name ${LambdaRoleName} | jq '.Role.Arn' | tr -d '"')
#export Role_ARN=$(aws sts get-caller-identity --output text --query Arn)
#export Role_ARN=$(aws iam get-role --role-name sam-app-createBookmarkRole-OJRWEFD7POQT | jq '.Role.Arn' | tr -d '"')
echo $Role_ARN
export Sam_Bucket=$(aws s3api list-buckets --query "Buckets[].Name" | grep samserverless | tr -d ',' | tr -d ' ' | tr -d '"')
echo $Sam_Bucket
#num=$(( $RANDOM % 10 +1 ))
#export Stack_Name="sam-app-$num"
export Stack_Name="sam-bookmark-app"
echo $Stack_Name
# Replace values in ./backend/samconfig.toml
sed -Ei "s|<LambdaRoleARN>|${Lambda_Role_ARN}|g" ./backend/samconfig.toml
sed -Ei "s|<replace_s3>|${Sam_Bucket}|g" ./backend/samconfig.toml
sed -Ei "s|<stack_name>|${Stack_Name}|g" ./backend/samconfig.toml
sed -Ei "s|<AWS_REGION>|${AWS_REGION}|g" ./backend/samconfig.toml
# Deploy backend using SAM
cd backend
sam deploy
# Task 3: App deployment: modify ./frontend/src/aws-exports.js configuration
export user_pool_id=$(aws cognito-idp list-user-pools --max-results 4 | jq '.UserPools[0].Id' | tr -d '"') 
echo $user_pool_id
export app_id=$(aws cognito-idp list-user-pool-clients --user-pool-id ${user_pool_id} | jq '.UserPoolClients[0].ClientId' | tr -d '"')
echo $app_id
export apiGWId=$(aws cloudformation describe-stack-resource  --stack-name ${Stack_Name} --logical-resource-id api | jq '.StackResourceDetail.PhysicalResourceId' | tr -d '"')
echo $apiGWId
# Change directory to environment
cd ~/environment/app-code
# Replacing values ./frontend/src/aws-exports.js
sed -Ei "s|<AWS_REGION>|${AWS_REGION}|g" ./frontend/src/aws-exports.js
sed -Ei "s|<pool_id>|${user_pool_id}|g" ./frontend/src/aws-exports.js
sed -Ei "s|<app_id>|${app_id}|g" ./frontend/src/aws-exports.js
sed -Ei "s|<apigwID>|${apiGWId}|g" ./frontend/src/aws-exports.js
# Task 3: Install NPM and build for deployment
cd ./frontend
npm install
npm run build
# Zip the build file
cd dist
zip -r app.zip *
aws s3 cp app.zip s3://${Sam_Bucket}