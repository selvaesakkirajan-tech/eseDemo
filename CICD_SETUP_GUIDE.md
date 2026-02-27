# Azure CI/CD Pipeline Implementation Guide

## Overview
This guide walks through the complete Azure CI/CD setup using Azure Pipelines, AKS, and Terraform.

### Architecture
```
┌─────────────┐
│   GitHub    │ ─ Trigger on commit
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│   Azure Pipelines               │
│  ├─ Build stage                 │
│  │  ├─ Run tests                │
│  │  ├─ Build Docker image       │
│  │  └─ Push to ACR              │
│  └─ Deploy stage                │
│     ├─ Terraform provision      │
│     └─ Helm deploy to AKS       │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│   Azure Resources               │
│  ├─ ACR (Container Registry)    │
│  ├─ AKS (Kubernetes Cluster)    │
│  ├─ Virtual Network             │
│  └─ Application Insights        │
└─────────────────────────────────┘
```

## Prerequisites

1. **Azure Subscription** with proper permissions
2. **Azure DevOps Project** (or Azure Pipelines linked to GitHub)
3. **GitHub Repository** with this code
4. **Docker** for testing locally
5. **Terraform** >= 1.5.0
6. **kubectl** for Kubernetes management
7. **Helm** >= 3.12.0

## Step 1: Setup Azure DevOps Service Connections

### Create Service Connection for Azure RM

1. Go to **Project Settings** → **Service Connections**
2. Click **Create Service Connection** → Select **Azure Resource Manager**
3. Choose **Service Principal (Automatic)**
4. Select your subscription
5. Name it: `azure-connection`
6. Grant admin access to manage all subscriptions
7. Save

### Create Service Connection for Container Registry

1. Create another service connection
2. Select **Docker Registry**
3. Configure with your ACR details:
   - **Registry Type**: Azure Container Registry
   - **Azure Subscription**: Select your subscription
   - **Azure Container Registry**: Will be created by Terraform
4. Name it: `acr-connection`

## Step 2: Set Pipeline Variables

Go to **Pipelines** → **Library** and create a variable group named `azure-cicd`:

```
ACR_REGISTRY_URL: <your-acr>.azurecr.io  (will be populated after first TF run)
ACR_USERNAME: (populated after first TF run)
ACR_PASSWORD: (populated after first TF run)
AZURE_SUBSCRIPTION_ID: <your-subscription-id>
AKS_RESOURCE_GROUP: dev-esedemo-rg
AKS_CLUSTER_NAME: dev-esedemo-aks
TF_STATE_RG: <resource-group-for-terraform-state>
TF_STATE_STORAGE: <storage-account-for-terraform-state>
```

## Step 3: Update Helm Chart Values

Update `manifests/helm/python-api/values.yaml` with your settings:

```yaml
# Update with your domain
ingress:
  hosts:
    - host: python-api.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
```

## Step 4: Update Terraform Variables

Customize `infra/env/dev/terraform.tfvars`:

```hcl
environment        = "dev"
azure_region       = "eastus"      # Change to your region
node_count         = 2
vm_size            = "Standard_B2s" # Adjust for your needs
```

## Step 5: Create Pipeline in Azure DevOps

### Option A: Import from YAML File

1. In Azure DevOps, go to **Pipelines** → **Create Pipeline**
2. Select **GitHub** as source
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Select `/azure-pipelines.yml`
6. Click **Continue** → **Save and Run**

### Option B: Manual Creation

1. Create new pipeline
2. Copy content from `/azure-pipelines.yml` into the pipeline editor
3. Save and run

## Step 6: First Run Setup

The first pipeline run will:

1. **Build**: 
   - Runs Python tests
   - Builds Docker image
   - Pushes to temp registry (will fail on first run due to ACR not existing yet)

2. **Provision Infrastructure**:
   - Creates resource group
   - Provisions ACR
   - Creates virtual network
   - Deploys AKS cluster
   - Sets up Application Insights
   - Takes ~15-20 minutes

3. **Deploy Application**:
   - Gets AKS credentials
   - Updates Helm values
   - Deploys python-api to AKS

## Step 7: Verify Deployment

After pipeline completes:

```bash
# Get AKS credentials
az aks get-credentials --resource-group dev-esedemo-rg --name dev-esedemo-aks

# Check Helm deployments
helm list

# Check pods
kubectl get pods

# Check services
kubectl get svc

# Get application URL
kubectl get ingress
```

## Environment Variables in Pipeline

### Build Stage Variables
| Variable | Purpose |
|----------|---------|
| `Build.BuildId` | Unique build number for Docker tags |
| `DOCKER_IMAGE_NAME` | Name of Docker image (python-api) |

### Deploy Stage Variables
| Variable | Purpose |
|----------|---------|
| `ACR_REGISTRY_URL` | Container registry URL |
| `AKS_CLUSTER_NAME` | Kubernetes cluster name |
| `AKS_RESOURCE_GROUP` | Resource group containing AKS |

## CI/CD Workflow

### On Commit to Main/Develop
1. Pipeline triggers automatically
2. Runs tests on Python API
3. Builds Docker image
4. Pushes image to ACR with build ID tag
5. Provisions/updates infrastructure with Terraform
6. Deploys using Helm to AKS
7. Verifies deployment with rollout status

### Monitoring Deployments

**Check Pipeline Logs:**
- Go to **Pipelines** → **Runs** → Select latest run
- View logs for each job and task

**Monitor in Azure Portal:**
- Navigate to your resource group
- View AKS cluster health
- Check Application Insights metrics
- Review container registry repositories

## Helm Deployment Details

### Chart Structure
```
python-api/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── templates/
│   ├── _helpers.tpl       # Template helpers
│   ├── deployment.yaml    # Kubernetes Deployment
│   ├── service.yaml       # Kubernetes Service
│   ├── ingress.yaml       # Ingress configuration
│   └── hpa.yaml          # Horizontal Pod Autoscaler
```

### Deployment Strategy
- **Deployment Type**: Rolling update
- **Replicas**: 2 (configurable)
- **Auto-scaling**: 2-5 pods based on CPU usage
- **Probes**: 
  - Liveness: Checks /docs endpoint every 10 seconds
  - Readiness: Checks /docs endpoint every 5 seconds

## Terraform State Management

### State Backend Configuration

The pipeline stores Terraform state in Azure Storage:

1. Create storage account for tfstate:
```bash
az storage account create \
  --name tfstatestg \
  --resource-group your-rg \
  --location eastus \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name tfstatestg
```

2. Get storage account key and use in pipeline

## Common Issues & Solutions

### Issue: Pipeline fails to push to ACR
**Solution**: Verify `acr-connection` service connection credentials after first Terraform run

### Issue: AKS deployment fails
**Solution**: Check kubectl configuration
```bash
az aks get-credentials --resource-group dev-esedemo-rg --name dev-esedemo-aks
```

### Issue: Helm chart fails
**Solution**: Validate chart syntax
```bash
helm lint manifests/helm/python-api
```

### Issue: Terraform state lock
**Solution**: Check Azure Storage for lease locks
```bash
az storage blob list --container-name tfstate --account-name tfstatestg
```

## Next Steps

1. **Add Monitoring**: Configure Application Insights alerts
2. **Setup GitOps**: Consider Flux CD for automatic deployments
3. **Add Secrets**: Integrate Azure Key Vault
4. **Multi-Environment**: Extend to QA and Prod stages
5. **Compliance**: Add policy checks and security scanning

## Useful Commands

```bash
# Get AKS credentials
az aks get-credentials --resource-group dev-esedemo-rg --name dev-esedemo-aks

# Check current context
kubectl config current-context

# List all resources
kubectl get all

# View pod logs
kubectl logs -f deployment/python-api

# Port forward to service
kubectl port-forward svc/python-api 8080:80

# Validate Helm chart
helm lint manifests/helm/python-api

# Dry-run Helm deployment
helm install python-api manifests/helm/python-api --dry-run --debug

# Uninstall Helm release
helm uninstall python-api

# Terraform validate
terraform -chdir=infra validate

# Terraform format
terraform -chdir=infra fmt -recursive
```

## Security Best Practices

1. ✅ Use managed identity for AKS-to-ACR authentication
2. ✅ Store secrets in Azure Key Vault
3. ✅ Enable Azure Policy on AKS
4. ✅ Use network policies for pod communication
5. ✅ Enable monitoring with Application Insights
6. ✅ Implement resource quotas per namespace
7. ✅ Use RBAC for role-based access control

## Cost Optimization Tips

- Start with `Standard_B2s` VMs for dev (lowest cost)
- Set node count to minimum for non-prod
- Use `Basic` ACR tier for dev
- Configure auto-shutdown for dev environments
- Monitor with Azure Cost Management

## Support & Resources

- [Azure Pipelines Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/)
- [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
