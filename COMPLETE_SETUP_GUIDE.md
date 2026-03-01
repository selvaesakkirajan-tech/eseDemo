# Complete Setup Guide - All Steps in One Place

**Total Time: 1-2 hours**

Follow these steps in exact order. Do not skip any step.

---

## 🔵 PHASE 1: AZURE PORTAL SETUP (15 min)

### STEP 1.1: Create Resource Groups

**In Azure Portal:**

1. Search: "Resource groups"
2. Click **+ Create**
3. Create first RG:
   - **Name**: `dev-esedemo-rg`
   - **Region**: East US (or your region)
   - Click **Review + Create** → **Create**

4. Create second RG (for Terraform state):
   - **Name**: `terraform-state-rg`
   - **Region**: Same as above
   - Click **Review + Create** → **Create**

---

### STEP 1.2: Create Storage Account (for Terraform State)

**In Azure Portal:**

1. Search: "Storage accounts"
2. Click **+ Create**
3. Fill in:
   - **Resource Group**: `terraform-state-rg`
   - **Storage account name**: `tfstate<random6digits>` (must be unique)
     - Example: `tfstate270484`
   - **Region**: Same as above
   - **Redundancy**: LRS
   - Click **Add** → **Next**
4. Click **Review** → **Create**

5. After creation, click the storage account
6. Click **Containers** (left sidebar)
7. Click **+ Container**
   - **Name**: `tfstate`
   - Click **Create**

**✅ SAVE these values:**
```
TF_STATE_RG = terraform-state-rg
TF_STATE_STORAGE = tfstate<your-random-numbers>
```

---

### STEP 1.3: Create Container Registry (ACR)

**In Azure Portal:**

1. Search: "Container registries"
2. Click **+ Create**
3. Fill in:
   - **Resource Group**: `dev-esedemo-rg`
   - **Registry name**: `esedemo<random6digits>` (must be unique, no dashes)
     - Example: `esedemo123456`
   - **Location**: Same region
   - **SKU**: Basic
   - Click **Review + Create** → **Create**

**✅ SAVE this value:**
```
ACR_NAME = esedemo<your-random-numbers>
ACR_REGISTRY_URL = esedemo<your-random-numbers>.azurecr.io
```

---

### STEP 1.4: Get Your Subscription ID

**In Azure Portal:**

1. Search: "Subscriptions"
2. Click on your subscription
3. Copy the **Subscription ID**

**✅ SAVE this value:**
```
AZURE_SUBSCRIPTION_ID = <your-subscription-id>
```

---

## 🟢 PHASE 2: CREATE SERVICE PRINCIPAL (10 min)

### STEP 2.1: Run PowerShell Script

**On your Windows machine (PowerShell x86):**

1. Open PowerShell (Run as Administrator)
2. Navigate to project folder:
   ```powershell
   cd C:\Project\ese_DemoClone
   ```
3. Run the script:
   ```powershell
   .\scripts\create-service-principal.ps1
   ```
4. When prompted, enter (from STEP 1.4):
   ```
   Subscription ID: <your-subscription-id>
   ```

5. Script will output credentials. **✅ SAVE everything:**
   ```
   App ID (Client ID)        = <AppId>
   Password (Secret)         = <Secret>
   Tenant ID                 = <TenantId>
   Subscription ID           = <SubscriptionId>
   ```

6. Script also creates: `azure-credentials.env`
   - Check file in project root
   - **⚠️ DO NOT commit to Git** (add to .gitignore)

---

## 🟣 PHASE 3: AZURE DEVOPS SETUP (20 min)

### STEP 3.1: Create Azure DevOps Organization & Project

**In Azure DevOps (https://dev.azure.com):**

1. Sign in with your Microsoft account
2. Click **+ Create new organization**
3. Enter organization name (e.g., `ese-demo`)
4. Select region → **Continue**
5. Create new project:
   - **Project name**: `ese-demo-clone`
   - **Visibility**: Private
   - Click **Create project**

**✅ SAVE this URL:**
```
Azure DevOps URL: https://dev.azure.com/selvaesakkirajan/esedemo
```

---

### STEP 3.2: Connect GitHub Repository

**In Azure DevOps Project:**

1. Go to **Repos** (left sidebar)
2. Click **Import repository**
3. Source type: **Git**
4. Clone URL: `https://github.com/<your-username>/ese-DemoClone.git`
5. Click **Import**
6. Wait for import to complete

---

### STEP 3.3: Create Service Connection - Azure (azure-connection)

**In Azure DevOps Project:**

1. Go to **Project Settings** (bottom left) → **Service Connections**
2. Click **New Service Connection** → **Azure Resource Manager**
3. Authentication method: **Service Principal (manual)**
4. Fill in (from STEP 2.1):
   ```
   Subscription ID        = <from STEP 1.4>
   Subscription Name      = <your subscription name>
   Service Principal ID   = <AppId from STEP 2.1>
   Service Principal key  = <Secret from STEP 2.1>
   Tenant ID             = <TenantId from STEP 2.1>
   ```
5. Service connection name: `azure-connection`
6. Click **Verify and save**

---

### STEP 3.4: Create Service Connection - Container Registry (acr-connection)

**In Azure DevOps Project:**

1. Go to **Project Settings** → **Service Connections**
2. Click **New Service Connection** → **Docker Registry**
3. Registry type: **Azure Container Registry**
4. Azure subscription: (select from dropdown)
5. Azure container registry: (select your ACR created in STEP 1.3)
6. Service connection name: `acr-connection`
7. Click **Save**

---

### STEP 3.5: Create SonarCloud Service Connection (sonarcloud-connection)

**First - Get SonarCloud Token (STEP 3.5a):**

1. Go to https://sonarcloud.io
2. Click **Sign up** → **Sign up with GitHub**
3. Create organization with your GitHub org name
4. Go to **Account** (profile icon) → **Security**
5. Type in token name: `azure-pipelines-token`
6. Click **Generate**
7. **Copy the token and save it**

**Then - Create Service Connection (STEP 3.5b):**

1. Go back to Azure DevOps → **Project Settings** → **Service Connections**
2. Click **New Service Connection** → **Generic**
3. Fill in:
   ```
   Server URL              = https://sonarcloud.io
   Username                = SonarCloud
   Password                = <token from STEP 3.5a>
   Service connection name = sonarcloud-connection
   ```
4. Click **Save**

---

## 🔴 PHASE 4: PIPELINE VARIABLES & CREDENTIALS (10 min)

### STEP 4.1: Create Variable Group in Azure DevOps

**In Azure DevOps Project:**

1. Go to **Pipelines** (left sidebar) → **Library**
2. Click **+ Variable group**
3. Name: `azure-cicd`
4. Add these variables (click **+ Add**):

   ```
   AZURE_SUBSCRIPTION_ID   = <from STEP 1.4>
   AKS_RESOURCE_GROUP      = dev-esedemo-rg
   AKS_CLUSTER_NAME        = dev-esedemo-aks
   TF_STATE_RG             = terraform-state-rg
   TF_STATE_STORAGE        = tfstate<your-numbers> (from STEP 1.2)
   SONAR_ORG               = <your-github-org-name>
   ```

5. Click **Save**

---

### STEP 4.2: Add ACR Credentials to Variable Group

**In Azure DevOps:**

1. Go to **Pipelines** → **Library** → `azure-cicd` variable group
2. Click **Edit**
3. Add these variables (get from Portal):

   **Get ACR username/password from Azure Portal:**
   - Go to your ACR → **Access keys** (left sidebar)
   - Copy: **Username**, **password**

   Back in Variable Group, add:
   ```
   ACR_REGISTRY_URL   = esedemo<your-numbers>.azurecr.io
   ACR_USERNAME       = <from ACR Access Keys>
   ACR_PASSWORD       = <from ACR Access Keys> (mark as Secret)
   ```

4. Click **Save**

---

## 🟠 PHASE 5: SETUP TERRAFORM STATE (5 min)

### STEP 5.1: Grant Service Principal Access to Storage Account

**In PowerShell:**

1. Open PowerShell (Run as Administrator)
2. Run this command:
   ```powershell
   # Login with the service principal
   $AppId = "<AppId from STEP 2.1>"
   $Secret = "<Secret from STEP 2.1>"
   $TenantId = "<TenantId from STEP 2.1>"
   $SubscriptionId = "<SubscriptionId from STEP 1.4>"
   
   $SecureSecret = ConvertTo-SecureString -String $Secret -AsPlainText -Force
   $Credential = New-Object System.Management.Automation.PSCredential($AppId, $SecureSecret)
   
   Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $TenantId -Subscription $SubscriptionId
   
   # Grant storage account access
   $StorageRG = "terraform-state-rg"
   $StorageName = "tfstate<your-numbers>"
   $StorageId = (Get-AzStorageAccount -ResourceGroupName $StorageRG -Name $StorageName).Id
   
   New-AzRoleAssignment -ObjectId (Get-AzADServicePrincipal -AppId $AppId).Id `
     -RoleDefinitionName "Storage Account Key Operator Service Role" `
     -Scope $StorageId
   
   New-AzRoleAssignment -ObjectId (Get-AzADServicePrincipal -AppId $AppId).Id `
     -RoleDefinitionName "Contributor" `
     -Scope $StorageId
   ```

3. If you see "Role assignment created successfully" → ✅ Done!

---

## 🔵 PHASE 6: CREATE PIPELINE IN AZURE DEVOPS (5 min)

### STEP 6.1: Create Pipeline from YAML

**In Azure DevOps Project:**

1. Go to **Pipelines** (left sidebar) → **Pipelines**
2. Click **Create Pipeline**
3. Select **Azure Repos Git**
4. Select your repo: `ese-DemoClone`
5. Select **Existing Azure Pipelines YAML file**
6. Select: **Branch**: main, **Path**: `/azure-pipelines.yml`
7. Click **Continue**
8. Click **Save and run** (or just **Save** if you want to review first)

---

## 🟢 PHASE 7: FIRST PIPELINE RUN (10 min)

### STEP 7.1: Manually Trigger Pipeline

**In Azure DevOps:**

1. Go to **Pipelines** → **Pipelines**
2. Click on your pipeline
3. Click **Run pipeline**
4. Click **Run**

**Watch the pipeline execute:**
- ✅ Build stage (5-10 min)
  - Install Python
  - Run tests
  - Build Docker image
  - Push to ACR
  - SonarCloud analysis
- ✅ Deploy stage (15-20 min)
  - Terraform init
  - Terraform plan
  - Terraform apply (creates AKS, ACR, network, App Insights)
  - Helm deploy (creates pods + LoadBalancer service)

---

## 🟡 PHASE 8: VERIFY DEPLOYMENT (5 min)

### STEP 8.1: Get LoadBalancer Public IP

**After pipeline completes:**

1. Go to **Pipelines** → Your completed pipeline
2. Click the **Deploy** stage → **Verify Helm deployment** task
3. Look for: `--- LoadBalancer IP ---` followed by an IP address

**Or run from PowerShell:**
```powershell
kubectl get svc python-api -n default
```
Copy the `EXTERNAL-IP` column value.

**✅ SAVE this IP address:**
```
LOADBALANCER_IP = xxx.xxx.xxx.xxx
```

---

### STEP 8.2: Test Your API

**In PowerShell:**

```powershell
# Replace with your IP from STEP 8.1
$IP = "xxx.xxx.xxx.xxx"

# Test the API
Invoke-RestMethod -Uri "http://$IP/sum?a=5&b=3"

# Expected response: {"sum":8}
```

**✅ If you get `{"sum":8}` → Everything is working!**

---

## 📋 CHECKLIST - Print This & Check Off As You Go

```
PHASE 1 - AZURE PORTAL
☐ Create dev-esedemo-rg resource group
☐ Create terraform-state-rg resource group
☐ Create storage account (tfstate...)
☐ Create tfstate container in storage
☐ Create Container Registry (esedemo...)
☐ Get Subscription ID

PHASE 2 - SERVICE PRINCIPAL
☐ Run create-service-principal.ps1
☐ Save App ID, Secret, Tenant ID
☐ Save azure-credentials.env file

PHASE 3 - AZURE DEVOPS
☐ Create Azure DevOps organization
☐ Create ese-demo-clone project
☐ Import GitHub repository
☐ Create azure-connection service connection
☐ Create acr-connection service connection
☐ Create sonarcloud-connection service connection

PHASE 4 - VARIABLES
☐ Create azure-cicd variable group
☐ Add all required variables
☐ Add ACR_REGISTRY_URL, ACR_USERNAME, ACR_PASSWORD

PHASE 5 - TERRAFORM STATE
☐ Run PowerShell role assignment commands

PHASE 6 - PIPELINE
☐ Create pipeline from azure-pipelines.yml

PHASE 7 - FIRST RUN
☐ Trigger pipeline manually
☐ Wait for Build stage (10 min)
☐ Wait for Deploy stage (20 min)

PHASE 8 - VERIFY
☐ Get LoadBalancer public IP (from Verify Helm deployment task)
☐ Test API endpoint
☐ Confirm response: {"sum":8}
```

---

## ❌ Common Mistakes to Avoid

1. ❌ Storage account name has uppercase or dashes
   - ✅ Use lowercase only: `tfstate123456`

2. ❌ Container Registry name has dashes
   - ✅ Use lowercase only: `esedemo123456`

3. ❌ Service principal secret expires
   - ✅ Don't lose it - save immediately

4. ❌ Forget to save credentials.env
   - ✅ Save immediately after script runs

5. ❌ Run pipeline without creating service connections first
   - ✅ Create service connections FIRST

6. ❌ Don't add variables to pipeline
   - ✅ Create variable group BEFORE running pipeline

---

## 🆘 If Something Fails

| Error | Solution |
|-------|----------|
| "Storage account already exists" | Use different random numbers (tfstate456789) |
| "Service principal unauthorized" | Check subscription ID is correct in STEP 1.4 |
| "Service connection failed" | Verify service principal ID and secret in STEP 3.3 |
| "Pipeline not found" | Make sure azure-pipelines.yml is in repo root |
| "API endpoint not responding" | Wait 2-3 minutes for LoadBalancer IP to be assigned, then check `kubectl get svc python-api -n default` |

---

## ✅ DONE! 

You now have:
- ✅ Azure resources (AKS, ACR, App Insights)
- ✅ Service principal for authentication
- ✅ Azure DevOps pipeline configured
- ✅ CI/CD automation (test → build → deploy)
- ✅ Code quality checks (SonarCloud)
- ✅ Live API exposed via Kubernetes LoadBalancer

**Your API is live at:** `http://<LOADBALANCER_IP>/sum?a=1&b=2`

🎉 **Complete!**
