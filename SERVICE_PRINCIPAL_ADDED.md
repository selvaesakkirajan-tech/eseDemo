# 🔐 Service Principal & Azure DevOps Setup - What's New

## What Was Added

You were absolutely right - we need **service principals** and **service connections** for authentication. Here's what has been created:

### 📄 Documentation
- **[SERVICE_PRINCIPAL_SETUP.md](SERVICE_PRINCIPAL_SETUP.md)** (⭐ NEW - Start here!)
  - Complete guide to Azure service principals
  - Why they're needed
  - Step-by-step creation instructions
  - Azure DevOps service connection setup
  - Security best practices
  - Troubleshooting guide

### 🛠️ Automation Scripts
- **[scripts/create-service-principal.ps1](scripts/create-service-principal.ps1)** (⭐ Windows)
  - Fully automated service principal creation
  - Interactive user prompts
  - Credential file generation
  - Azure DevOps CLI instructions
  - Takes ~2 minutes to run

- **[scripts/create-service-principal.sh](scripts/create-service-principal.sh)** (⭐ Linux/Mac)
  - Bash version of the PowerShell script
  - Same features and functionality
  - Works on Linux and macOS

### 📝 Updated Documentation
- **INDEX.md** - Now highlights service principal setup as FIRST step
- **IMPLEMENTATION_SUMMARY.md** - Updated quick start to include Step 0
- **CICD_QUICK_REFERENCE.md** - Added service principal checklist at the beginning

---

## 🎯 How It Works

### Service Principal (Azure Side)
```
What it is: A user identity for applications/services
Located in: Azure Active Directory (Entra ID)
Permissions: Defined by role assignments (e.g., Contributor)
Use case: Terraform needs to authenticate to Azure to create resources
```

### Service Connection (Azure DevOps Side)
```
What it is: A secure connection from Azure Pipelines to Azure
Located in: Project Settings → Service Connections
Contains: Service principal credentials + metadata
Uses: Authenticate pipeline tasks to Azure services
```

### The Flow
```
┌─ Terraform Task in Pipeline ─┐
│  Needs to create AKS, ACR    │
└──────────┬────────────────────┘
           │
           ▼
┌─ Azure DevOps Service Connection ─┐
│  (named: azure-connection)        │
└──────────┬───────────────────────┘
           │ Contains credentials
           ▼
┌─ Service Principal ─┐
│  appId              │
│  password (secret)  │
│  tenant             │
└──────────┬──────────┘
           │
           ▼
┌─ Azure Subscription ─┐
│  Authenticated!      │
│  Create resources    │
└──────────────────────┘
```

---

## 🚀 Quick Start (3 Steps)

### Step 1: Create Service Principal (5 minutes)
```powershell
# Windows
.\scripts\create-service-principal.ps1

# Or Linux/Mac
bash scripts/create-service-principal.sh
```

This script will:
- ✅ Prompt you for subscription ID
- ✅ Create a service principal
- ✅ Save credentials to `azure-credentials.env`
- ✅ Show you instructions for Azure DevOps

### Step 2: Create Service Connection in Azure DevOps (5 minutes)
Use credentials from Step 1 to create service connection:
1. Azure DevOps → Project Settings → Service Connections
2. New service connection → Azure Resource Manager
3. Fill in Service Principal ID, Password, Tenant ID
4. Name it: `azure-connection`
5. Save and verify

### Step 3: Continue with Pipeline Setup
Follow IMPLEMENTATION_SUMMARY.md for remaining steps

---

## 📋 What the Script Does

### Checks
```powershell
✓ Verifies Azure CLI installed
✓ Checks for Azure DevOps CLI
✓ Validates subscription access
```

### Creates
```powershell
✓ Service Principal with Contributor role
✓ Assignment to your subscription
✓ Returns credentials (appId, password, tenantId)
```

### Saves
```powershell
✓ Credentials to azure-credentials.env
✓ Encrypted (not visible in terminal)
✓ Ready for Azure DevOps service connection
```

### Provides
```powershell
✓ Step-by-step Azure DevOps setup instructions
✓ CLI commands if Azure DevOps CLI installed
✓ Portal instructions if manual setup needed
```

---

## 🔐 Security Notes

### ✅ DO
- ✅ Run script on your local machine (secure)
- ✅ Store credentials in Azure Key Vault long-term
- ✅ Add `azure-credentials.env` to `.gitignore`
- ✅ Save service connection credentials securely
- ✅ Use only in Azure DevOps variables (encrypted)
- ✅ Rotate credentials every 6-12 months

### ❌ DON'T
- ❌ Commit `azure-credentials.env` to git
- ❌ Share credentials in Slack/Email/Teams
- ❌ Use in local scripts permanently
- ❌ Expose in pipeline logs
- ❌ Use same principal for multiple environments

---

## 📊 What the Credentials Look Like

After running the script, you'll get:

```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "esedemo-cicd-principal",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

**Use these values in Azure DevOps:**
- **Service Principal ID** = appId
- **Service Principal Key** = password
- **Tenant ID** = tenant

---

## 🆘 Troubleshooting

### Issue: Script says "Azure CLI not found"
**Solution**: Install Azure CLI
```bash
# Windows
# Download from: https://aka.ms/installazurecliwindows

# Or via package manager
choco install azure-cli

# macOS
brew install azure-cli

# Linux (Ubuntu)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Issue: "Subscription not found"
**Solution**: Verify you have access
```powershell
az account list --output table  # Check available subscriptions
az account show --subscription YOUR_ID  # Verify specific subscription
```

### Issue: Service connection verification fails in Azure DevOps
**Solution**: Check credential values
```powershell
# Verify service principal exists
az ad sp show --id [appId] --output table

# Check role assignment
az role assignment list --assignee [appId] --output table
```

### Issue: "Permission denied" when running pipeline
**Solution**: Add more permissions
```powershell
# Check current permissions
az role assignment list --assignee [appId] --output table

# Add Contributor role if missing
az role assignment create `
    --assignee [appId] `
    --role "Contributor" `
    --scope "/subscriptions/$SUBSCRIPTION_ID"
```

---

## 📚 Documentation Reference

| Document | Purpose | Read Time |
|----------|---------|-----------|
| SERVICE_PRINCIPAL_SETUP.md | Complete guide | 15-20 min |
| scripts/create-service-principal.ps1 | Automation (Windows) | 5 min |
| scripts/create-service-principal.sh | Automation (Linux/Mac) | 5 min |
| IMPLEMENTATION_SUMMARY.md | Overview after SP setup | 5 min |
| CICD_SETUP_GUIDE.md | Full details | 30 min |

---

## ✅ Checklist

```
Service Principal Creation
☐ Read SERVICE_PRINCIPAL_SETUP.md
☐ Run create-service-principal script (Windows or Linux)
☐ Save credentials securely
☐ Add azure-credentials.env to .gitignore

Azure DevOps Setup
☐ Create service connection "azure-connection" with credentials
☐ Verify connection works
☐ Create service connection "acr-connection" (after ACR exists)

Pipeline Variables
☐ Set AZURE_SUBSCRIPTION_ID
☐ Set TF_STATE_RG and TF_STATE_STORAGE (after Terraform run)
☐ Test pipeline with small change
☐ Monitor logs for auth issues
```

---

## 🎉 Summary

You were right! Authentication credentials are critical:

✅ **Scripts provided** - Fully automated service principal creation  
✅ **Documentation complete** - Service principal guide with troubleshooting  
✅ **Security focused** - Best practices included  
✅ **Easy to use** - Interactive scripts with clear instructions  

**Next Step**: Read [SERVICE_PRINCIPAL_SETUP.md](SERVICE_PRINCIPAL_SETUP.md) and run the script! 🚀

---

*The Azure CI/CD pipeline is now fully complete with authentication setup.* ✨
