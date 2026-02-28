#!/bin/bash

# Setup Terraform State Storage for Azure Pipelines
# This script creates the necessary Azure Storage account to store Terraform state

set -e

echo "========================================="
echo "Terraform State Storage Setup"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Azure CLI found${NC}"
echo ""

# Get inputs
read -p "Enter Azure Subscription ID: " SUBSCRIPTION_ID
read -p "Enter Resource Group name (for Terraform state): " TF_STATE_RG
read -p "Enter Storage Account name (must be globally unique, lowercase): " TF_STATE_STORAGE
read -p "Enter Azure Region (default: eastus): " AZURE_REGION
AZURE_REGION=${AZURE_REGION:-eastus}

echo ""
echo "========================================="
echo "Summary:"
echo "  Subscription: $SUBSCRIPTION_ID"
echo "  Resource Group: $TF_STATE_RG"
echo "  Storage Account: $TF_STATE_STORAGE"
echo "  Region: $AZURE_REGION"
echo "========================================="
echo ""

read -p "Continue? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "Setting subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

echo "Creating resource group..."
az group create \
    --name "$TF_STATE_RG" \
    --location "$AZURE_REGION"

echo "Creating storage account..."
az storage account create \
    --name "$TF_STATE_STORAGE" \
    --resource-group "$TF_STATE_RG" \
    --location "$AZURE_REGION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --encryption-services blob \
    --https-only true

echo "Creating storage container..."
az storage container create \
    --name tfstate \
    --account-name "$TF_STATE_STORAGE"

echo ""
echo "========================================="
echo -e "${GREEN}✓ Terraform state storage setup complete!${NC}"
echo "========================================="
echo ""
echo "Update your pipeline variables:"
echo "  TF_STATE_RG: $TF_STATE_RG"
echo "  TF_STATE_STORAGE: $TF_STATE_STORAGE"
echo ""
echo "Get storage account key for backend config:"
STORAGE_KEY=$(az storage account keys list \
    --resource-group "$TF_STATE_RG" \
    --account-name "$TF_STATE_STORAGE" \
    --query '[0].value' \
    -o tsv)
echo "  Key: $STORAGE_KEY"
echo ""
echo "Terraform backend config:"
echo "  resource_group_name         = \"$TF_STATE_RG\""
echo "  storage_account_name        = \"$TF_STATE_STORAGE\""
echo "  container_name              = \"tfstate\""
echo "  key                         = \"dev.tfstate\""
echo ""
