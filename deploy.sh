#!/bin/bash

# Check if required environment variables are set
if [ -z "$DEEPSEEK_API_KEY" ]; then
    echo "Error: DEEPSEEK_API_KEY environment variable is not set"
    echo "Please set it with: export DEEPSEEK_API_KEY=your-api-key-here"
    exit 1
fi

if [ -z "$DOMAIN_NAME" ]; then
    echo "Error: DOMAIN_NAME environment variable is not set"
    echo "Please set it with: export DOMAIN_NAME=cards.yourdomain.com"
    exit 1
fi

if [ -z "$ACM_CERTIFICATE_ARN" ]; then
    echo "Error: ACM_CERTIFICATE_ARN environment variable is not set"
    echo "Please set it with: export ACM_CERTIFICATE_ARN=arn:aws:acm:..."
    exit 1
fi

# Build the SAM application
sam build

# Deploy the SAM application with parameters
sam deploy \
    --parameter-overrides \
    DeepSeekApiKey="$DEEPSEEK_API_KEY" \
    DomainName="$DOMAIN_NAME" \
    ACMCertificateArn="$ACM_CERTIFICATE_ARN"

# Update Frontend scripts with Cloudformation Outputs

# Retrieve CloudFormation outputs
outputs=$(aws cloudformation describe-stacks --stack-name biz-card-scanner --query "Stacks[0].Outputs" --region ap-southeast-1)

# Extract outputs
region=$(echo $outputs | jq -r '.[] | select(.OutputKey=="Region") | .OutputValue')
userPoolId=$(echo $outputs | jq -r '.[] | select(.OutputKey=="MainUserpool") | .OutputValue')
clientId=$(echo $outputs | jq -r '.[] | select(.OutputKey=="MainUserpoolClient") | .OutputValue')
identityPoolId=$(echo $outputs | jq -r '.[] | select(.OutputKey=="MainIdentityPool") | .OutputValue')
frontendBucket=$(echo $outputs | jq -r '.[] | select(.OutputKey=="FrontendBucketName") | .OutputValue')
frontendBucket="muirwood-cards-prod-2025"
backendBucket=$(echo $outputs | jq -r '.[] | select(.OutputKey=="BackendBucketName") | .OutputValue')
apiGW=$(echo $outputs | jq -r '.[] | select(.OutputKey=="MainAPIGateway") | .OutputValue')
cfid=$(echo $outputs | jq -r '.[] | select(.OutputKey=="MainCloudFrontDistributionId") | .OutputValue')

# Change directory to frontend bucket folder
cd FrontendBucket

# Create app-config.js with injected values
cat <<EOL > app-config.js
window.__APP_CONFIG__ = {
  apiBaseUrl: '$apiGW',
  cognito: {
    userPoolId: '$userPoolId',
    clientId: '$clientId',
    domain: 'muirwood-cards'
  }
};
EOL

# Copy the folder content to the S3 bucket (includes app-config.js)
aws s3 cp . s3://$frontendBucket --recursive

cat <<EOL > app-config.js
window.__APP_CONFIG__ = {
  apiBaseUrl: '',
  cognito: {
    userPoolId: '',
    clientId: '',
    domain: 'muirwood-cards'
  }
};
EOL

# create testUser
aws cognito-idp admin-create-user --username testUser --region $region --user-pool-id $userPoolId
aws cognito-idp admin-set-user-password --user-pool-id $userPoolId --username testUser --password 12345678! --region $region --permanent

# create cloudfront invalidation
aws cloudfront create-invalidation --distribution-id $cfid --paths "/*" --region $region
