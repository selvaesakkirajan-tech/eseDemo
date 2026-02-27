# Azure Service Principal & Service Connection Setup

## Overview

Azure Pipelines needs **service connections** to authenticate with your Azure subscription and other services. Behind each service connection is a **service principal** that provides the actual credentials.

### What We Need to Create

1. **Service Principal for Azure Resource Manager** (Terraform, AKS, ACR)
   - Permission level: Contributor on subscription
   - Used by: Terraform provisioning, AKS deployment

2. **Service Principal for Azure Container Registry** (Docker push/pull)
   - Permission level: AcrPush on specific ACR
   - Used by: Pipeline pushing images to ACR

---

## Prerequisites

```powershell
# Check if Azure CLI is installed
az version

# If not installed, install from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
```

---

## Step 1: Get Your Subscription Info

```powershell
# List all subscriptions
az account list --output table

# Get the subscription ID you want to use
$SUBSCRIPTION_ID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Set as default subscription
az account set --subscription $SUBSCRIPTION_ID

# Verify
az account show --output table
```

---

## Step 2: Create Service Principal for Azure Resource Manager

This service principal will have broad permissions to create and manage Azure resources via Terraform.

### Option A: Using PowerShell Script (Recommended)

```powershell
# Parameters
$SUBSCRIPTION_ID = "your-subscription-id"
$SERVICE_PRINCIPAL_NAME = "esedemo-cicd-principal"
$ROLE = "Contributor"  # Broad permissions for dev environment

# Create the service principal
$sp = az ad sp create-for-rbac `
    --name $SERVICE_PRINCIPAL_NAME `
    --role $ROLE `
    --scopes "/subscriptions/$SUBSCRIPTION_ID" `
    --output json | ConvertFrom-Json

# Output the credentials
Write-Host "=== Service Principal Created ===" -ForegroundColor Green
Write-Host "appId (Client ID):       $($sp.appId)"
Write-Host "password (Client Secret): $($sp.password)"
Write-Host "tenant (Tenant ID):       $($sp.tenant)"
Write-Host ""
Write-Host "⚠️ SAVE THESE CREDENTIALS! You'll use them to create the Azure DevOps service connection."
```

### Option B: Using Azure CLI

```bash
SUBSCRIPTION_ID="your-subscription-id"
SERVICE_PRINCIPAL_NAME="esedemo-cicd-principal"
ROLE="Contributor"

az ad sp create-for-rbac \
    --name $SERVICE_PRINCIPAL_NAME \
    --role $ROLE \
    --scopes "/subscriptions/$SUBSCRIPTION_ID"
```

### Output Example
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "esedemo-cicd-principal",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

**Save these values!** You'll need them for the Azure DevOps service connection.

---

## Step 3: Create Service Connection in Azure DevOps

### Using the Azure DevOps Portal (Manual)

1. **Go to Azure DevOps**
   - Navigate to your project
   - Click **Project Settings** (bottom left)
   - Select **Service Connections**

2. **Create New Service Connection**
   - Click **New service connection**
   - Select **Azure Resource Manager**
   - Choose **Service Principal (manual)**

3. **Fill in Service Principal Details**
   ```
   Subscription ID:    [Your subscription ID]
   Subscription Name:  [Friendly name like "Dev" or "Production"]
   Service Principal ID (appId):     [from step 2]
   Service Principal Key (password): [from step 2]
   Tenant ID:          [from step 2]
   ```

4. **Verify and Save**
   - Click **Verify** to test the connection
   - Click **Save** if verification succeeds
   - Name it: `azure-connection`

### Using PowerShell Script (Automated)

Unfortunately, Azure DevOps service connections require manual setup through the portal OR using Azure DevOps CLI. Here's the CLI approach:

```bash
# Install Azure DevOps CLI extension (if not already installed)
az extension add --name azure-devops

# Set default org and project
$ORG_URL = "https://dev.azure.com/your-organization"
$PROJECT = "your-project-name"
az devops configure --defaults organization=$ORG_URL project=$PROJECT

# Create service connection via CLI
az devops service-endpoint azurerm create \
    --name azure-connection \
    --azure-rm-service-principal-id [appId] \
    --azure-rm-service-principal-key [password] \
    --azure-rm-subscription-id [subscription-id] \
    --azure-rm-subscription-name "Dev Subscription" \
    --azure-rm-tenant-id [tenant]
```

---

## Step 4: Create Service Connection for Container Registry

Once you have created your ACR (via Terraform), create a service connection for it:

### Option A: Manual Portal Setup

1. **Create New Service Connection**
   - Click **New service connection**
   - Select **Docker Registry**

2. **Configure Details**
   ```
   Registry Type: Azure Container Registry
   Azure Subscription: [select your subscription]
   Azure Container Registry: [select from dropdown]
   Service Connection Name: acr-connection
   ```

3. **Verify and Save**
   - Click **Verify** to test
   - Save as `acr-connection`

### Option B: After First Pipeline Run

The ACR service principal can be created automatically after Terraform provisions the registry. In that case, you can add the connection manually through the portal once ACR exists.

---

## Step 5: Verify Service Connections

### In Azure DevOps Portal

1. Go to **Project Settings** → **Service Connections**
2. You should see:
   - ✅ `azure-connection` - Azure Resource Manager
   - ✅ `acr-connection` - Container Registry

3. Click each and verify the connection works

---

## Step 6: Update Pipeline to Use Service Connections

The `azure-pipelines.yml` already references these service connections:

```yaml
# In Terraform tasks
backendServiceArm: 'azure-connection'

# In Docker and Helm tasks
containerRegistry: 'acr-connection'
```

No changes needed to the pipeline file if you name your service connections correctly!

---

## Security Best Practices

### ✅ Do's
- ✅ Store service principal credentials securely
- ✅ Use strong passwords (Azure generates secure ones)
- ✅ Limit service principal permissions (use specific roles)
- ✅ Rotate credentials periodically
- ✅ Use different principals for different environments
- ✅ Enable Azure Policy for access control
- ✅ Store secrets in Azure Key Vault for sensitive values

### ❌ Don'ts
- ❌ Don't commit credentials to git
- ❌ Don't share credentials in Slack/Email
- ❌ Don't use Contributor role if a more specific role suffices
- ❌ Don't expose credentials in pipeline logs
- ❌ Don't use the same principal for multiple environments

---

## Minimum Required Permissions

### For Terraform/AKS Deployment (azure-connection)

For a more restricted setup (best practice for production), use these specific roles instead of `Contributor`:

```powershell
# Create with specific roles for different resources
$SUBSCRIPTION_ID = "your-subscription-id"

# Option 1: Least privilege approach (assign specific roles)
az role assignment create `
    --assignee $SP_OBJECT_ID `
    --role "Contributor" `
    --scope "/subscriptions/$SUBSCRIPTION_ID"

# This includes permissions for:
# - Create/manage resource groups
# - Create/manage AKS clusters
# - Create/manage container registries
# - Create/manage networking
# - Create/manage monitoring resources
```

For **production**, consider these more restrictive roles:
- `User Access Administrator` (for RBAC)
- `Kubernetes Service Cluster Admin`
- `Azure Container Registry Contributor`
- `Network Contributor`

---

## Troubleshooting Service Principal Issues

### Issue: Service Connection Verification Fails

**Symptoms**: Red "Verify" button or "Connection failed" error

**Solutions**:
1. Verify credentials are correct:
   ```powershell
   az account show --subscription $SUBSCRIPTION_ID
   ```

2. Check service principal exists:
   ```powershell
   az ad sp show --id [appId]
   ```

3. Verify role assignment:
   ```powershell
   az role assignment list --assignee [appId]
   ```

4. Ensure account has permissions:
   ```powershell
   az account list --query "[].{name:name, id:id, subscriptionId:id}"
   ```

### Issue: Pipeline Fails with "Unauthorized" Error

**Symptoms**: Terraform or AKS tasks fail with permission denied

**Solutions**:
1. Check service principal role:
   ```powershell
   az role assignment list --assignee [appId] --output table
   ```

2. Add more permissions if needed:
   ```powershell
   az role assignment create `
       --assignee [appId] `
       --role "Owner" `
       --scope "/subscriptions/$SUBSCRIPTION_ID"
   ```

3. Verify in Azure portal:
   - Go to **Subscriptions** → **Access control (IAM)**
   - Search for service principal by name
   - Verify role assignment

### Issue: Cannot Find Service Connection in Pipeline

**Symptoms**: Pipeline configuration shows "Service connection not found"

**Solutions**:
1. Verify service connection name matches exactly (case-sensitive)
2. Ensure service connection is in the correct project
3. Check that your Azure DevOps user has permission to manage service connections
4. Try adding the service connection name in quotes: `'azure-connection'`

---

## Advanced: Rotating Service Principal Credentials

Over time, you may want to rotate credentials for security reasons:

```powershell
# Get the service principal 
$SP_ID = "the-app-id"

# Create new credential
$NEW_PASSWORD = az ad app credential reset --id $SP_ID --output tsv

# Update in Azure DevOps service connection with new password
# Go to Service Connection settings and update the password field

# Delete old credential (if multiple exist)
az ad app credential delete --id $SP_ID --key-id [old-key-id]
```

---

## Summary: Service Connection Checklist

```
Service Principal (Azure)
☐ Created service principal with correct subscription scope
☐ Saved appId, password, and tenant ID
☐ Verified role assignment (Contributor or appropriate role)

Azure DevOps Service Connections
☐ Created "azure-connection" (Azure Resource Manager)
  - Service Principal ID: [appId]
  - Service Principal Key: [password]
  - Tenant ID: [tenant]
☐ Verified connection (blue checkmark)

☐ Created "acr-connection" (Container Registry)
  - Linked to Azure subscription
  - ACR selected from dropdown
☐ Verified connection (blue checkmark)

Pipeline Configuration
☐ azure-pipelines.yml references correct service connection names
☐ Variable group includes correct subscription ID
☐ ACR registry URL matches your ACR login server

Testing
☐ Run test pipeline to verify connections work
☐ Monitor for authentication errors
☐ Check Terraform logs for successful Azure auth
```

---

## Quick Reference Commands

```powershell
# List all service principals in tenant
az ad sp list --all --output table

# Get service principal details
az ad sp show --id [appId] --output table

# Check role assignments for service principal
az role assignment list --assignee [appId] --output table

# Create new service principal
az ad sp create-for-rbac --name [name] --role [role] --scopes "/subscriptions/[subid]"

# Delete service principal (if needed)
az ad sp delete --id [appId]

# Update service principal password
az ad app credential reset --id [appId]

# Verify current subscription
az account show --output table

# List all subscriptions
az account list --output table
```

---

## Related Documentation

- [Microsoft: Service Principals in Azure](https://learn.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)
- [Azure DevOps: Service Connections](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
- [Azure CLI: AD Service Principal Commands](https://learn.microsoft.com/en-us/cli/azure/ad/sp)
- [Azure RBAC: Built-in Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)

---

## Next Steps

1. ✅ Create service principal using Step 2 script
2. ✅ Create service connections in Azure DevOps (Step 3-4)
3. ✅ Verify connections work (Step 5)
4. ✅ Run pipeline to test authentication
5. ✅ Monitor logs for any permission issues

Once service connections are set up, your pipeline will automatically authenticate with Azure! 🔐
