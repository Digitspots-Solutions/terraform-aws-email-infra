#!/bin/bash
set -e

# Arguments: alias region profile
ALIAS=$1
REGION=$2
PROFILE=$3

# Check if organization with this alias already exists
ORG_ID=$(aws workmail list-organizations \
  --region "$REGION" \
  --profile "$PROFILE" \
  --query "OrganizationSummaries[?Alias=='$ALIAS'].OrganizationId" \
  --output text)

if [ "$ORG_ID" == "None" ] || [ -z "$ORG_ID" ]; then
  # Create Organization (this will create a new directory-less org)
  ORG_ID=$(aws workmail create-organization \
    --alias "$ALIAS" \
    --region "$REGION" \
    --profile "$PROFILE" \
    --query "OrganizationId" \
    --output text)
  echo "Created WorkMail organization: $ORG_ID"
else
  echo "WorkMail organization already exists: $ORG_ID"
fi
