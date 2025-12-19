#!/bin/bash
set -e

# Read JSON from stdin
eval "$(jq -r '@sh "ALIAS=\(.alias) REGION=\(.region) PROFILE=\(.profile)"')"

# Build profile argument only if profile is set and not empty
PROFILE_ARG=""
if [ -n "$PROFILE" ] && [ "$PROFILE" != "null" ]; then
  PROFILE_ARG="--profile $PROFILE"
fi

# Check if organization with this alias exists AND is Active
ORG_ID=$(aws workmail list-organizations \
  --region "$REGION" \
  $PROFILE_ARG \
  --query "OrganizationSummaries[?Alias=='$ALIAS' && State=='Active'].OrganizationId | [0]" \
  --output text 2>/dev/null || echo "")

# Clean up the result (AWS returns "None" for empty results)
if [ "$ORG_ID" == "None" ] || [ -z "$ORG_ID" ]; then
  # Create Organization (this will create a new directory-less org)
  ORG_ID=$(aws workmail create-organization \
    --alias "$ALIAS" \
    --region "$REGION" \
    $PROFILE_ARG \
    --query "OrganizationId" \
    --output text)
  
  # Wait for org to become active
  for i in {1..30}; do
    STATE=$(aws workmail describe-organization \
      --organization-id "$ORG_ID" \
      --region "$REGION" \
      $PROFILE_ARG \
      --query "State" \
      --output text 2>/dev/null || echo "Pending")
    if [ "$STATE" == "Active" ]; then
      break
    fi
    sleep 5
  done
fi

# Output JSON
jq -n --arg org_id "$ORG_ID" '{"org_id": $org_id}'
