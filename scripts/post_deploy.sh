#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-biz-card-scanner}"
REGION="${2:-us-east-1}"

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required (brew install jq)"; exit 1; }

echo "Reading outputs: stack=$STACK_NAME region=$REGION"
outputs_json="$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query 'Stacks[0].Outputs' \
  --output json)"

get_out () { echo "$outputs_json" | jq -r --arg k "$1" '.[] | select(.OutputKey==$k) | .OutputValue'; }

FRONTEND_BUCKET_NAME="$(get_out FrontendBucketName)"
BACKEND_BUCKET_NAME="$(get_out BackendBucketName)"
USER_POOL_ID="$(get_out MainUserpool)"
USER_POOL_CLIENT_ID="$(get_out MainUserpoolClient)"
IDENTITY_POOL_ID="$(get_out MainIdentityPool)"
API_BASE_URL="$(get_out MainAPIGateway)"
STACK_REGION="$(get_out Region)"; [[ -z "${STACK_REGION}" || "${STACK_REGION}" == "null" ]] && STACK_REGION="$REGION"

[[ -z "${FRONTEND_BUCKET_NAME}" || "${FRONTEND_BUCKET_NAME}" == "null" ]] && { echo "ERROR: FrontendBucketName output missing"; exit 1; }
[[ -z "${API_BASE_URL}" || "${API_BASE_URL}" == "null" ]] && { echo "ERROR: MainAPIGateway output missing"; exit 1; }

mkdir -p FrontendBucket
cat > FrontendBucket/app-config.js <<CFG
window.APP_CONFIG = {
  region: "${STACK_REGION}",
  userPoolId: "${USER_POOL_ID}",
  userPoolClientId: "${USER_POOL_CLIENT_ID}",
  identityPoolId: "${IDENTITY_POOL_ID}",
  apiBaseUrl: "${API_BASE_URL}",
  appName: "Interactive Card Reader Muir Wood"
};
CFG
echo "Wrote FrontendBucket/app-config.js"

echo "Sync FrontendBucket/ -> s3://${FRONTEND_BUCKET_NAME}/"
aws s3 sync FrontendBucket/ "s3://${FRONTEND_BUCKET_NAME}/" --delete --region "$REGION"

echo "Done."
echo "Frontend: s3://${FRONTEND_BUCKET_NAME}/"
echo "API: ${API_BASE_URL}"

