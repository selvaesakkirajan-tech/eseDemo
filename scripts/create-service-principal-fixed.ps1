# Azure Service Principal & DevOps Service Connection Setup
# Clean, minimal, encoding-safe version

param(
    [string]$SubscriptionId,
    [string]$ServicePrincipalName = "esedemo-cicd-principal",
    [string]$Role = "Contributor",
    [switch]$Interactive = $true
)

$ErrorActionPreference = "Stop"

function Write-Info { param([string]$m) Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Success { param([string]$m) Write-Host "[SUCCESS] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err { param([string]$m) Write-Host "[ERROR] $m" -ForegroundColor Red }

Write-Info "Starting Azure service principal creation"

# Preconditions
try { az version > $null 2>&1; Write-Success "Azure CLI is installed" } catch { Write-Err "Azure CLI not found. Install Azure CLI."; exit 1 }

if (-not $SubscriptionId) {
    Write-Info "Available subscriptions:"
    az account list --output table
    $SubscriptionId = Read-Host "Enter your Subscription ID (GUID)"
}

try {
    $subscription = az account show --subscription $SubscriptionId --output json | ConvertFrom-Json
    Write-Success "Found subscription: $($subscription.name) ($SubscriptionId)"
    $SubscriptionName = $subscription.name
} catch {
    Write-Err "Subscription not found: $SubscriptionId"; exit 1
}

if ($Interactive) {
    $confirm = Read-Host "Continue with creating service principal '$ServicePrincipalName' in subscription '$SubscriptionName'? (y/n)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') { Write-Warn "Cancelled by user"; exit 0 }
}

Write-Info "Creating service principal..."
try {
    $spJson = az ad sp create-for-rbac --name $ServicePrincipalName --role $Role --scopes "/subscriptions/$SubscriptionId" --output json
    $sp = $spJson | ConvertFrom-Json
    Write-Success "Service principal created: $($sp.appId)"
} catch {
    Write-Err "Failed to create service principal: $_"; exit 1
}

# Save credentials
$credsPath = Join-Path $PWD 'azure-credentials.env'
$lines = @(
    "SUBSCRIPTION_ID=$SubscriptionId",
    "SUBSCRIPTION_NAME=$SubscriptionName",
    "SERVICE_PRINCIPAL_NAME=$ServicePrincipalName",
    "CLIENT_ID=$($sp.appId)",
    "CLIENT_SECRET=$($sp.password)",
    "TENANT_ID=$($sp.tenant)"
)
$lines | Out-File -FilePath $credsPath -Encoding UTF8
Write-Success "Saved credentials to: $credsPath"

# Add to .gitignore
if (!(Test-Path .gitignore)) { New-Item -Path .gitignore -ItemType File -Force | Out-Null }
if (-not (Select-String -Path .gitignore -Pattern 'azure-credentials.env' -Quiet)) { Add-Content .gitignore 'azure-credentials.env'; Write-Success "Added azure-credentials.env to .gitignore" } else { Write-Info "azure-credentials.env already in .gitignore" }

# Verify role assignment (may take a minute)
Write-Info "Verifying role assignment for SP (may take a moment):"
az role assignment list --assignee $sp.appId --scope "/subscriptions/$SubscriptionId" -o table

Write-Success "Service principal setup complete"
Write-Info "Keep the file 'azure-credentials.env' secure and do not commit it to source control."
