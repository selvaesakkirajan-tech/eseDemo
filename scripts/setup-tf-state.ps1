# Setup Terraform State Storage for Azure Pipelines (PowerShell)
# This script creates the necessary Azure Storage account to store Terraform state

param(
    [string]$SubscriptionId,
    [string]$TfStateRg = "tf-state-rg",
    [string]$TfStateStorage,
    [string]$AzureRegion = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Terraform State Storage Setup (PowerShell)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
try {
    $az = Get-Command az -ErrorAction Stop
    Write-Host "✓ Azure CLI found" -ForegroundColor Green
}
catch {
    Write-Host "❌ Azure CLI not found. Please install it first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Get inputs if not provided
if (-not $SubscriptionId) {
    $SubscriptionId = Read-Host "Enter Azure Subscription ID"
}

if (-not $TfStateStorage) {
    $TfStateStorage = Read-Host "Enter Storage Account name (must be globally unique, lowercase)"
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Subscription: $SubscriptionId" -ForegroundColor Gray
Write-Host "  Resource Group: $TfStateRg" -ForegroundColor Gray
Write-Host "  Storage Account: $TfStateStorage" -ForegroundColor Gray
Write-Host "  Region: $AzureRegion" -ForegroundColor Gray
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$continue = Read-Host "Continue? (y/n)"
if ($continue -ne "y" -and $continue -ne "Y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Setting subscription..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId

Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create --name $TfStateRg --location $AzureRegion

Write-Host "Creating storage account..." -ForegroundColor Yellow
az storage account create `
    --name $TfStateStorage `
    --resource-group $TfStateRg `
    --location $AzureRegion `
    --sku Standard_LRS `
    --kind StorageV2 `
    --encryption-services blob `
    --https-only true

Write-Host "Creating storage container..." -ForegroundColor Yellow
az storage container create `
    --name tfstate `
    --account-name $TfStateStorage

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "✓ Terraform state storage setup complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Update your pipeline variables:" -ForegroundColor Cyan
Write-Host "  TF_STATE_RG: $TfStateRg" -ForegroundColor Gray
Write-Host "  TF_STATE_STORAGE: $TfStateStorage" -ForegroundColor Gray
Write-Host ""

Write-Host "Get storage account key for backend config:" -ForegroundColor Cyan
$storageKey = az storage account keys list `
    --resource-group $TfStateRg `
    --account-name $TfStateStorage `
    --query "[0].value" `
    -o tsv
Write-Host "  Key: $storageKey" -ForegroundColor Gray
Write-Host ""

Write-Host "Terraform backend config:" -ForegroundColor Cyan
Write-Host "  resource_group_name         = `"$TfStateRg`"" -ForegroundColor Gray
Write-Host "  storage_account_name        = `"$TfStateStorage`"" -ForegroundColor Gray
Write-Host "  container_name              = `"tfstate`"" -ForegroundColor Gray
Write-Host "  key                         = `"dev.tfstate`"" -ForegroundColor Gray
Write-Host ""
