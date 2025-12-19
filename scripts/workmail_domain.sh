#!/bin/bash
set -e

# Read JSON from stdin
eval "$(jq -r '@sh "ORG_ID=\(.org_id) DOMAIN=\(.domain) REGION=\(.region) PROFILE=\(.profile)"')"

# 1. Register Domain (Idempotent: ignore error if already exists)
aws workmail register-mail-domain \
  --organization-id "$ORG_ID" \
  --domain-name "$DOMAIN" \
  --region "$REGION" \
  --profile "$PROFILE" 2>/dev/null || true

# 2. Get Domain Details
DETAILS=$(aws workmail get-mail-domain \
  --organization-id "$ORG_ID" \
  --domain-name "$DOMAIN" \
  --region "$REGION" \
  --profile "$PROFILE")

# 3. Extract Records - Get FIRST of each type for core verification
# TXT Record for Verification (first one is the ownership verification)
TXT_NAME=$(echo "$DETAILS" | jq -r '[.Records[] | select(.Type == "TXT")] | .[0].Hostname // empty')
TXT_VALUE=$(echo "$DETAILS" | jq -r '[.Records[] | select(.Type == "TXT")] | .[0].Value // empty')

# CNAME for Autodiscover (first one is typically autodiscover)
CNAME_NAME=$(echo "$DETAILS" | jq -r '[.Records[] | select(.Type == "CNAME")] | .[0].Hostname // empty')
CNAME_VALUE=$(echo "$DETAILS" | jq -r '[.Records[] | select(.Type == "CNAME")] | .[0].Value // empty')

# MX Record for mail delivery (REQUIRED for domain verification and user registration)
MX_NAME=$(echo "$DETAILS" | jq -r '[.Records[] | select(.Type == "MX")] | .[0].Hostname // empty')
MX_VALUE=$(echo "$DETAILS" | jq -r '[.Records[] | select(.Type == "MX")] | .[0].Value // empty')

# Output JSON
jq -n \
  --arg txt_name "$TXT_NAME" \
  --arg txt_value "$TXT_VALUE" \
  --arg cname_name "$CNAME_NAME" \
  --arg cname_value "$CNAME_VALUE" \
  --arg mx_name "$MX_NAME" \
  --arg mx_value "$MX_VALUE" \
  '{"txt_name": $txt_name, "txt_value": $txt_value, "cname_name": $cname_name, "cname_value": $cname_value, "mx_name": $mx_name, "mx_value": $mx_value}'
