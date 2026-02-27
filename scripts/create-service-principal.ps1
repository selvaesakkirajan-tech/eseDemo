# Azure Service Principal & DevOps Service Connection Setup
# This script automates the creation of service principals and prepares for Azure DevOps integration

param(
    [string]$SubscriptionId,
    [string]$ServicePrincipalName = "esedemo-cicd-principal",
    [string]$Role = "Contributor",
    [switch]$Interactive = $true
)

$ErrorActionPreference = "Stop"

#region Helper Functions
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Save-To-File {
    param(
        [string]$Filename,
        [string]$Content
    )
    $filepath = Join-Path $PSScriptRoot $Filename
    $Content | Out-File -FilePath $filepath -Encoding UTF8
    Write-Success "Saved to: $filepath"
    return $filepath
}
#endregion

#region Verification
Write-Header "Azure Service Principal Setup"

# Check Azure CLI
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
try {
    $null = az version
    Write-Success "Azure CLI is installed"
}
catch {
    Write-Error "Azure CLI not found. Install from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Check Azure DevOps CLI
try {
    $null = az devops --version 2>&1
    Write-Success "Azure DevOps CLI extension is installed"
    $hasDevOpsCli = $true
}
catch {
    Write-Warning "Azure DevOps CLI extension not found. Install with: az extension add --name azure-devops"
    $hasDevOpsCli = $false
}

Write-Host ""
#endregion

#region Get Subscription ID
if (-not $SubscriptionId) {
    Write-Host "Available subscriptions:" -ForegroundColor Yellow
    az account list --output table
    Write-Host ""
    $SubscriptionId = Read-Host "Enter your Subscription ID (GUID)"
}

# Verify subscription
Write-Host "Verifying subscription..." -ForegroundColor Yellow
try {
    $subscription = az account show --subscription $SubscriptionId --output json | ConvertFrom-Json
    Write-Success "Found subscription: $($subscription.name) ($SubscriptionId)"
    $SubscriptionName = $subscription.name
}
catch {
    Write-Error "Subscription not found: $SubscriptionId"
    exit 1
}

Write-Host ""
#endregion

#region Create Service Principal
Write-Header "Creating Service Principal"

Write-Host "Parameters:" -ForegroundColor Yellow
Write-Host "  Name: $ServicePrincipalName"
Write-Host "  Role: $Role"
Write-Host "  Scope: /subscriptions/$SubscriptionId"
Write-Host ""

if ($Interactive) {
    $confirm = Read-Host "Continue? (y/n)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Creating service principal..." -ForegroundColor Yellow

try {
    $json = az ad sp create-for-rbac `
        --name $ServicePrincipalName `
        --role $Role `
        --scopes "/subscriptions/$SubscriptionId" `
        --output json
    
    $servicePrincipal = $json | ConvertFrom-Json
    
    Write-Success "Service principal created successfully"
    Write-Host ""
    Write-Host "Service Principal Details:" -ForegroundColor Green
    Write-Host "  Display Name: $($servicePrincipal.displayName)"
    Write-Host "  App ID (Client ID): $($servicePrincipal.appId)"
    Write-Host "  Tenant ID: $($servicePrincipal.tenant)"
    Write-Host "  Password (Client Secret): [PROTECTED - see saved file]"
    Write-Host ""
}
catch {
    Write-Error "Failed to create service principal: $_"
    exit 1
}

Write-Host ""
#endregion

#region Save Credentials
Write-Header "Saving Credentials"

# Create a secure credentials file
$credentialsLines = @(
    '# Azure Service Principal Credentials'
    "# Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    '# KEEP THIS FILE SECURE - DO NOT COMMIT TO GIT!'
    ''
    "SUBSCRIPTION_ID=$SubscriptionId"
    "SUBSCRIPTION_NAME=$SubscriptionName"
    "SERVICE_PRINCIPAL_NAME=$ServicePrincipalName"
    "CLIENT_ID=$($servicePrincipal.appId)"
    "CLIENT_SECRET=$($servicePrincipal.password)"
    "TENANT_ID=$($servicePrincipal.tenant)"
    ''
    '# For Azure DevOps Service Connection:'
    "# Service Principal ID: $($servicePrincipal.appId)"
    "# Service Principal Key: [stored in CLIENT_SECRET above]"
    "# Tenant ID: $($servicePrincipal.tenant)"
)

$credentialsContent = $credentialsLines -join "`n"

$credsFile = Save-To-File "azure-credentials.env" $credentialsContent

Write-Warning "KEEP THIS FILE SECURE! Do not commit to git."
Write-Warning "Store credentials safely (Azure Key Vault, password manager, etc.)"
Write-Host ""

#endregion

#region Verify Role Assignment
Write-Header "Verifying Assignment"

Write-Host "Checking role assignment..." -ForegroundColor Yellow
$assignments = az role assignment list --assignee $($servicePrincipal.appId) --scope "/subscriptions/$SubscriptionId" --output json | ConvertFrom-Json

if ($assignments.Count -gt 0) {
    Write-Success "Role assignment confirmed"
    Write-Host ""
    Write-Host "Assigned Roles:" -ForegroundColor Green
    foreach ($assignment in $assignments) {
        Write-Host "  - $($assignment.roleDefinitionName)"
    }
}
else {
    Write-Warning "No role assignments found yet. They may take a moment to propagate."
}

Write-Host ""
#endregion

#region Azure DevOps Configuration
Write-Header "Azure DevOps Service Connection Setup"

if ($hasDevOpsCli) {
    Write-Host "Azure DevOps CLI is available. You can create service connections via CLI." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To create service connection via CLI:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "# Set your organization and project"
    Write-Host "az devops configure --defaults organization=https://dev.azure.com/YOUR_ORG project=YOUR_PROJECT"
    Write-Host ""
    Write-Host "# Create Azure Resource Manager service connection"
    Write-Host "az devops service-endpoint azurerm create \" -ForegroundColor Gray
    Write-Host "    --name azure-connection \" -ForegroundColor Gray
    Write-Host "    --azure-rm-service-principal-id $($servicePrincipal.appId) \" -ForegroundColor Gray
    Write-Host "    --azure-rm-service-principal-key [see credentials file] \" -ForegroundColor Gray
    Write-Host "    --azure-rm-subscription-id $SubscriptionId \" -ForegroundColor Gray
    Write-Host "    --azure-rm-subscription-name $SubscriptionName \" -ForegroundColor Gray
    Write-Host "    --azure-rm-tenant-id $($servicePrincipal.tenant)" -ForegroundColor Gray
}
else {
    Write-Host "IMPORTANT: Azure DevOps CLI is not installed." -ForegroundColor Yellow
    Write-Host "You'll need to create service connections manually in the Azure DevOps portal." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To create service connection in Azure DevOps Portal (Manual):" -ForegroundColor Cyan
Write-Host "1. Go to your Azure DevOps project"
Write-Host "2. Click Project Settings → Service Connections"
Write-Host "3. Click 'New service connection'"
Write-Host "4. Select 'Azure Resource Manager' → 'Service Principal (manual)'"
Write-Host "5. Fill in these details:"
Write-Host "   - Subscription ID: $SubscriptionId"
Write-Host "   - Subscription Name: $SubscriptionName"
Write-Host "   - Service Principal ID: $($servicePrincipal.appId)"
Write-Host "   - Service Principal Key: [From credentials file]"
Write-Host "   - Tenant ID: $($servicePrincipal.tenant)"
Write-Host "6. Name it: 'azure-connection'"
Write-Host "7. Click 'Save'"
Write-Host ""

#endregion

#region Alternative: Create with Environment Variables
Write-Header "Using Credentials in Scripts"

Write-Host "You can use these credentials in PowerShell:" -ForegroundColor Green
Write-Host ""
Write-Host "# Load from file"
Write-Host "Get-Content azure-credentials.env | ForEach-Object {"
Write-Host "    if (\$_ -match '^(.+?)=(.+)$') {"
Write-Host "        [Environment]::SetEnvironmentVariable([regex]::Match(\$_, '^(.+?)=').Groups[1].Value, \$matches[2])"
Write-Host "    }"
Write-Host "}"
Write-Host ""
Write-Host "# Or manually"
Write-Host "`$env:CLIENT_ID = '$($servicePrincipal.appId)'"
Write-Host "`$env:CLIENT_SECRET = '[from credentials file]'"
Write-Host "`$env:TENANT_ID = '$($servicePrincipal.tenant)'"
Write-Host "`$env:SUBSCRIPTION_ID = '$SubscriptionId'"
Write-Host ""

#endregion

#region Final Instructions
Write-Header "Next Steps"

Write-Host "1. ✅ Service principal created" -ForegroundColor Green
Write-Host "2. ⏳ Create Azure DevOps service connection (see instructions above)"
Write-Host "3. ⏳ Update your pipeline variables in Azure DevOps"
Write-Host "4. ⏳ Run your pipeline to test"
Write-Host ""
Write-Host "Security Reminders:" -ForegroundColor Yellow
Write-Host "• Store credentials securely (Azure Key Vault, password manager)"
Write-Host "• Add azure-credentials.env to .gitignore"
Write-Host "• Never commit credentials to git"
Write-Host "• Rotate credentials periodically"
Write-Host "• Use least privilege principle"
Write-Host ""

$savedPath = (Get-Item $credsFile).FullName
Write-Host "Credentials saved to:" -ForegroundColor Cyan
Write-Host "📁 $savedPath" -ForegroundColor Cyan
Write-Host ""

#endregion

Write-Host "✨ Service principal setup complete!" -ForegroundColor Green
Write-Host ""
