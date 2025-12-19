#!/bin/bash
set -e

# Read JSON from stdin
eval "$(jq -r '@sh "ALIAS=\(.alias) REGION=\(.region) PROFILE=\(.profile)"')"

# Check if organization with this alias exists (READ-ONLY - never creates)
ORG_ID=$(aws workmail list-organizations \
  --region "$REGION" \
  --profile "$PROFILE" \
  --query "OrganizationSummaries[?Alias=='$ALIAS'].OrganizationId" \
  --output text)

if [ "$ORG_ID" == "None" ] || [ -z "$ORG_ID" ]; then
  # Return empty - org doesn't exist
  jq -n '{"org_id": "", "exists": "false"}'
else
  # Return existing org
  jq -n --arg org_id "$ORG_ID" '{"org_id": $org_id, "exists": "true"}'
fi
