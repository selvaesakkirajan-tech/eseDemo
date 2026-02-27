#!/bin/bash

# Azure Service Principal & DevOps Service Connection Setup
# This script automates the creation of service principals for Azure Pipelines

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SERVICE_PRINCIPAL_NAME="${1:-esedemo-cicd-principal}"
ROLE="${2:-Contributor}"

# Helper functions
print_header() {
    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

save_to_file() {
    local filename=$1
    local content=$2
    local filepath="$(dirname "$0")/$filename"
    echo "$content" > "$filepath"
    print_success "Saved to: $filepath"
    echo "$filepath"
}

# Verification
print_header "Azure Service Principal Setup (Bash)"

echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Install from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi
print_success "Azure CLI is installed"

if az devops --version &> /dev/null 2>&1; then
    print_success "Azure DevOps CLI extension is installed"
    HAS_DEVOPS_CLI=true
else
    print_warning "Azure DevOps CLI extension not found. Install with: az extension add --name azure-devops"
    HAS_DEVOPS_CLI=false
fi

echo ""

# Get Subscription ID
echo -e "${YELLOW}Available subscriptions:${NC}"
az account list --output table
echo ""

read -p "Enter your Subscription ID (GUID): " SUBSCRIPTION_ID

# Verify subscription
echo -e "${YELLOW}Verifying subscription...${NC}"
if SUBSCRIPTION=$(az account show --subscription "$SUBSCRIPTION_ID" --output json); then
    SUBSCRIPTION_NAME=$(echo "$SUBSCRIPTION" | jq -r '.name')
    print_success "Found subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
else
    print_error "Subscription not found: $SUBSCRIPTION_ID"
    exit 1
fi

echo ""

# Create Service Principal
print_header "Creating Service Principal"

echo -e "${YELLOW}Parameters:${NC}"
echo "  Name: $SERVICE_PRINCIPAL_NAME"
echo "  Role: $ROLE"
echo "  Scope: /subscriptions/$SUBSCRIPTION_ID"
echo ""

read -p "Continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Creating service principal...${NC}"

if SERVICE_PRINCIPAL=$(az ad sp create-for-rbac \
    --name "$SERVICE_PRINCIPAL_NAME" \
    --role "$ROLE" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --output json); then
    
    print_success "Service principal created successfully"
    echo ""
    
    DISPLAY_NAME=$(echo "$SERVICE_PRINCIPAL" | jq -r '.displayName')
    APP_ID=$(echo "$SERVICE_PRINCIPAL" | jq -r '.appId')
    TENANT_ID=$(echo "$SERVICE_PRINCIPAL" | jq -r '.tenant')
    PASSWORD=$(echo "$SERVICE_PRINCIPAL" | jq -r '.password')
    
    echo -e "${GREEN}Service Principal Details:${NC}"
    echo "  Display Name: $DISPLAY_NAME"
    echo "  App ID (Client ID): $APP_ID"
    echo "  Tenant ID: $TENANT_ID"
    echo "  Password (Client Secret): [PROTECTED - see saved file]"
    echo ""
else
    print_error "Failed to create service principal"
    exit 1
fi

echo ""

# Save Credentials
print_header "Saving Credentials"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
CREDENTIALS_CONTENT="# Azure Service Principal Credentials
# Created: $TIMESTAMP
# ⚠️ KEEP THIS FILE SECURE - DO NOT COMMIT TO GIT!

SUBSCRIPTION_ID=\"$SUBSCRIPTION_ID\"
SUBSCRIPTION_NAME=\"$SUBSCRIPTION_NAME\"
SERVICE_PRINCIPAL_NAME=\"$SERVICE_PRINCIPAL_NAME\"
CLIENT_ID=\"$APP_ID\"
CLIENT_SECRET=\"$PASSWORD\"
TENANT_ID=\"$TENANT_ID\"

# For Azure DevOps Service Connection:
# Service Principal ID: $APP_ID
# Service Principal Key: $PASSWORD
# Tenant ID: $TENANT_ID
"

CREDS_FILE=$(save_to_file "azure-credentials.env" "$CREDENTIALS_CONTENT")

print_warning "Keep this file secure! Do not commit to git!"
print_warning "Store credentials safely (Azure Key Vault, password manager, etc.)"
echo ""

# Verify Role Assignment
print_header "Verifying Assignment"

echo -e "${YELLOW}Checking role assignment...${NC}"

ASSIGNMENTS=$(az role assignment list --assignee "$APP_ID" --scope "/subscriptions/$SUBSCRIPTION_ID" --output json)
COUNT=$(echo "$ASSIGNMENTS" | jq 'length')

if [ "$COUNT" -gt 0 ]; then
    print_success "Role assignment confirmed"
    echo ""
    echo -e "${GREEN}Assigned Roles:${NC}"
    echo "$ASSIGNMENTS" | jq -r '.[].roleDefinitionName' | while read role; do
        echo "  - $role"
    done
else
    print_warning "No role assignments found yet. They may take a moment to propagate."
fi

echo ""

# Azure DevOps Configuration
print_header "Azure DevOps Service Connection Setup"

if [ "$HAS_DEVOPS_CLI" = true ]; then
    echo -e "${CYAN}Azure DevOps CLI is available. You can create service connections via CLI.${NC}"
    echo ""
    echo -e "${YELLOW}To create service connection via CLI:${NC}"
    echo ""
    echo "# Set your organization and project"
    echo "az devops configure --defaults organization=https://dev.azure.com/YOUR_ORG project=YOUR_PROJECT"
    echo ""
    echo "# Create Azure Resource Manager service connection"
    echo "az devops service-endpoint azurerm create \\"
    echo "    --name azure-connection \\"
    echo "    --azure-rm-service-principal-id $APP_ID \\"
    echo "    --azure-rm-service-principal-key [see credentials file] \\"
    echo "    --azure-rm-subscription-id $SUBSCRIPTION_ID \\"
    echo "    --azure-rm-subscription-name \"$SUBSCRIPTION_NAME\" \\"
    echo "    --azure-rm-tenant-id $TENANT_ID"
else
    echo -e "${YELLOW}IMPORTANT: Azure DevOps CLI is not installed.${NC}"
    echo -e "${YELLOW}You'll need to create service connections manually in the Azure DevOps portal.${NC}"
fi

echo ""
echo -e "${CYAN}To create service connection in Azure DevOps Portal (Manual):${NC}"
echo "1. Go to your Azure DevOps project"
echo "2. Click Project Settings → Service Connections"
echo "3. Click 'New service connection'"
echo "4. Select 'Azure Resource Manager' → 'Service Principal (manual)'"
echo "5. Fill in these details:"
echo "   - Subscription ID: $SUBSCRIPTION_ID"
echo "   - Subscription Name: $SUBSCRIPTION_NAME"
echo "   - Service Principal ID: $APP_ID"
echo "   - Service Principal Key: [From credentials file]"
echo "   - Tenant ID: $TENANT_ID"
echo "6. Name it: 'azure-connection'"
echo "7. Click 'Save'"
echo ""

# Using Credentials
print_header "Using Credentials in Scripts"

echo -e "${GREEN}You can use these credentials in bash:${NC}"
echo ""
echo "# Load from file"
echo "source azure-credentials.env"
echo ""
echo "# Or manually"
echo "export CLIENT_ID='$APP_ID'"
echo "export CLIENT_SECRET='[from credentials file]'"
echo "export TENANT_ID='$TENANT_ID'"
echo "export SUBSCRIPTION_ID='$SUBSCRIPTION_ID'"
echo ""

# Final Instructions
print_header "Next Steps"

echo "1. ✅ Service principal created"
echo "2. ⏳ Create Azure DevOps service connection (see instructions above)"
echo "3. ⏳ Update your pipeline variables in Azure DevOps"
echo "4. ⏳ Run your pipeline to test"
echo ""
echo -e "${YELLOW}Security Reminders:${NC}"
echo "• Store credentials securely (Azure Key Vault, password manager)"
echo "• Add azure-credentials.env to .gitignore"
echo "• Never commit credentials to git"
echo "• Rotate credentials periodically"
echo "• Use least privilege principle"
echo ""
echo -e "${CYAN}Credentials saved to:${NC}"
echo "📁 $CREDS_FILE"
echo ""

echo -e "${GREEN}✨ Service principal setup complete!${NC}"
echo ""
