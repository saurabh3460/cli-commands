# Set Subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# Define the Service Principal Name
SP_NAME="provisioner"

# Define the Role & Scope
ROLE="Contributor"
SCOPE="/subscriptions/$SUBSCRIPTION_ID"

# Set Expiry Date for Credentials
EXPIRY_DATE="2025-04-30"


# Create a Service Principal

SP_DETAILS=$(az ad sp create-for-rbac --name $SP_NAME --role $ROLE --scopes $SCOPE --query "{appId:appId, password:password, tenant:tenant}" --output json)

# Extract Important Values
APP_ID=$(echo $SP_DETAILS | jq -r .appId)
CLIENT_SECRET=$(echo $SP_DETAILS | jq -r .password)
TENANT_ID=$(echo $SP_DETAILS | jq -r .tenant)


# Get Existing Service Principal Details

APP_ID=$(az ad sp list --display-name $SP_NAME --query "[0].appId" --output tsv)
OBJECT_ID=$(az ad sp show --id $APP_ID --query objectId --output tsv)
echo "App ID: $APP_ID"
echo "Object ID: $OBJECT_ID"

# Rotate (Renew) Credentials

NEW_CREDENTIAL=$(az ad sp credential reset --id $APP_ID --end-date "$EXPIRY_DATE" --query "{password:password}" --output json)

NEW_CLIENT_SECRET=$(echo $NEW_CREDENTIAL | jq -r .password)
echo "New Client Secret: $NEW_CLIENT_SECRET"


# Use a Certificate Instead of a Password (More Secure)

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout sp-key.pem -out sp-cert.pem -subj "/CN=$SP_NAME"

az ad sp credential reset --id $APP_ID --cert "@sp-cert.pem" --end-date "2026-04-30"
