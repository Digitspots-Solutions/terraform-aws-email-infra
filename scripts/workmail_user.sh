#!/bin/bash
set -e

ORG_ID=$1
USERNAME=$2
PASSWORD=$3
REGION=$4
PROFILE=$5
DOMAIN=$6

# Build profile argument only if profile is set and not empty
PROFILE_ARG=""
if [ -n "$PROFILE" ] && [ "$PROFILE" != "null" ]; then
  PROFILE_ARG="--profile $PROFILE"
fi

# =============================================================================
# Wait for Domain Verification (MX record propagation)
# =============================================================================
echo "Waiting for domain $DOMAIN to be verified..." >&2
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  DOMAIN_STATUS=$(aws workmail get-mail-domain \
    --organization-id "$ORG_ID" \
    --domain-name "$DOMAIN" \
    --region "$REGION" \
    $PROFILE_ARG \
    --query "IsDefault" \
    --output text 2>/dev/null || echo "PENDING")
  
  # Check if domain is verified by checking if it has records and is usable
  OWNERSHIP_STATUS=$(aws workmail get-mail-domain \
    --organization-id "$ORG_ID" \
    --domain-name "$DOMAIN" \
    --region "$REGION" \
    $PROFILE_ARG \
    --query "OwnershipVerificationStatus" \
    --output text 2>/dev/null || echo "PENDING")
  
  if [ "$OWNERSHIP_STATUS" == "VERIFIED" ]; then
    echo "Domain $DOMAIN is verified!" >&2
    break
  fi
  
  ATTEMPT=$((ATTEMPT + 1))
  echo "Domain verification pending (attempt $ATTEMPT/$MAX_ATTEMPTS, status: $OWNERSHIP_STATUS)..." >&2
  sleep 10
done

if [ "$OWNERSHIP_STATUS" != "VERIFIED" ]; then
  echo "WARNING: Domain not fully verified yet. Proceeding with user creation..." >&2
fi

# =============================================================================
# Get User Info (ID and State)
# =============================================================================
USER_INFO=$(aws workmail list-users \
  --organization-id "$ORG_ID" \
  --region "$REGION" \
  $PROFILE_ARG \
  --query "Users[?Name=='$USERNAME'].[Id,State]" \
  --output text)

USER_ID=$(echo "$USER_INFO" | awk '{print $1}')
USER_STATE=$(echo "$USER_INFO" | awk '{print $2}')

# Create user if doesn't exist
if [ "$USER_ID" == "None" ] || [ -z "$USER_ID" ]; then
  # Password is REQUIRED for new user creation
  if [ -z "$PASSWORD" ] || [ "$PASSWORD" == "null" ]; then
    echo "ERROR: Password is required to create new WorkMail user '$USERNAME'." >&2
    echo "Add '${DOMAIN}' key to your terraform.tfvars workmail_passwords map." >&2
    exit 1
  fi
  
  echo "Creating user $USERNAME..." >&2
  USER_ID=$(aws workmail create-user \
    --organization-id "$ORG_ID" \
    --name "$USERNAME" \
    --display-name "$USERNAME" \
    --password "$PASSWORD" \
    --region "$REGION" \
    $PROFILE_ARG \
    --query "UserId" \
    --output text)
  USER_STATE="DISABLED"
  echo "User created with ID: $USER_ID" >&2
else
  echo "User $USERNAME already exists (ID: $USER_ID, State: $USER_STATE)" >&2
fi

# Register user (enable mailbox) if not already enabled
if [ "$USER_STATE" == "DISABLED" ]; then
  EMAIL="${USERNAME}@${DOMAIN}"
  echo "Registering user $USERNAME with email $EMAIL..." >&2
  
  # Retry registration with exponential backoff (domain verification can take time)
  REGISTER_ATTEMPTS=12
  REGISTER_ATTEMPT=0
  REGISTER_SUCCESS=false
  SLEEP_TIME=10
  
  while [ $REGISTER_ATTEMPT -lt $REGISTER_ATTEMPTS ]; do
    REGISTER_ATTEMPT=$((REGISTER_ATTEMPT + 1))
    
    if aws workmail register-to-work-mail \
      --organization-id "$ORG_ID" \
      --entity-id "$USER_ID" \
      --email "$EMAIL" \
      --region "$REGION" \
      $PROFILE_ARG 2>&1; then
      REGISTER_SUCCESS=true
      echo "User registered successfully!" >&2
      break
    else
      echo "Registration attempt $REGISTER_ATTEMPT/$REGISTER_ATTEMPTS failed. Waiting ${SLEEP_TIME}s for DNS propagation..." >&2
      sleep $SLEEP_TIME
      # Increase wait time for next attempt (max 60s)
      SLEEP_TIME=$((SLEEP_TIME < 60 ? SLEEP_TIME + 10 : 60))
    fi
  done
  
  if [ "$REGISTER_SUCCESS" != "true" ]; then
    echo "ERROR: Failed to register user after $REGISTER_ATTEMPTS attempts." >&2
    echo "Domain may not be fully verified. Check MX record in Route53." >&2
    exit 1
  fi
else
  echo "User already registered (State: $USER_STATE)" >&2
fi
