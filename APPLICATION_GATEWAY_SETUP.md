# Azure Application Gateway with AGIC (IP-Only Access)

## Overview

Your CI/CD pipeline now uses **Azure Application Gateway (AGIC)** with **IP-only access** instead of Kubernetes Ingress with domain names.

### Architecture Change

**Before (Ingress-based):**
```
Internet → Domain Name → Ingress Controller → Service → Pod
                (kubernetes.io pointing to IP)
```

**After (Application Gateway-based):**
```
Internet → Public IP → Application Gateway (AGIC) → AKS Service → Pod
           (no domain needed)
```

---

## What Changed

### 1. Terraform Infrastructure
- ✅ **New Module**: `infra/modules/appgw_agic/`
  - Creates Azure Application Gateway
  - Allocates public IP address
  - Sets up AGIC managed identity
  - Creates dedicated subnet for App Gateway

- ✅ **Updated**: `infra/variables.tf`
  - `appgw_subnet_cidr` - Subnet for App Gateway (10.0.2.0/24)
  - `appgw_sku_name` - Standard_v2 (configurable)
  - `appgw_sku_tier` - Standard_v2 (configurable)
  - `appgw_capacity` - Instance count (default: 2)

- ✅ **Updated**: `infra/main.tf`
  - Includes `module "appgw_agic"`
  - Outputs the public IP address

### 2. Helm Configuration
- ✅ **Disabled Kubernetes Ingress**
  - `ingress.enabled = false`
  - No domain names or TLS certificates needed

- ✅ **Added App Gateway Configuration**
  - `appGateway.enabled = true`
  - `appGateway.publicIP` - Set from Terraform
  - IP-based access pattern

### 3. Network Architecture
- **Subnet 1 (10.0.1.0/24)**: AKS cluster nodes
- **Subnet 2 (10.0.2.0/24)**: Application Gateway (new)
- **VNet (10.0.0.0/16)**: Overall network

---

## How It Works

### Network Flow

```
┌─────────────────────────────────────────────────┐
│           Azure Virtual Network                 │
│         (10.0.0.0/16)                           │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Application Gateway Subnet             │   │
│  │  (10.0.2.0/24)                          │   │
│  │  ┌─────────────────────────────────┐    │   │
│  │  │  App Gateway                    │    │   │
│  │  │  - Public IP: xxx.xxx.xxx.xxx  │◄───┼─┐ │
│  │  │  - Port 80, 443 listening      │    │ │ │
│  │  └──────────────┬──────────────────┘    │ │ │
│  │                 │ Backend Pool           │ │ │
│  │                 ▼ (10.0.1.0/24)          │ │ │
│  └─────────────────────────────────────────┘ │ │
│                    │                          │ │
│  ┌─────────────────▼──────────────────────┐  │ │
│  │  AKS Cluster Subnet                    │  │ │
│  │  (10.0.1.0/24)                         │  │ │
│  │  ┌──────────────────────────────────┐  │  │ │
│  │  │ Kubernetes Service ClusterIP     │  │  │ │
│  │  │ Port: 80 → 8080                  │  │  │ │
│  │  │ ┌────────────────────────────┐   │  │  │ │
│  │  │ │ Pod 1: python-api:8080├────┼──┼──┘ │
│  │  │ └────────────────────────────┘   │     │
│  │  │ ┌────────────────────────────┐   │     │
│  │  │ │ Pod 2: python-api:8080     │   │     │
│  │  │ └────────────────────────────┘   │     │
│  │  └──────────────────────────────────┘  │
│  │                                         │
│  └─────────────────────────────────────────┘
│                                                 │
└─────────────────────────────────────────────────┘

↑
Internet/Public Web
```

### Traffic Path

1. **Client requests**: `http://52.168.123.45:80/sum?a=1&b=2`
2. **App Gateway** receives request on public IP
3. **Backend pool** routes to Service IP
4. **Kubernetes Service** (ClusterIP) load balances to pods
5. **Pod receives** request and responds

---

## Accessing Your API

### Before (Domain-based)
```
https://python-api.example.com/sum?a=1&b=2
```

### Now (IP-only)
```
http://<APPGW_PUBLIC_IP>:80/sum?a=1&b=2
```

### Get the Public IP

After Terraform completes:

```bash
# From Terraform output
terraform output appgw_public_ip

# Or from Azure CLI
az network public-ip show \
  --resource-group dev-esedemo-rg \
  --name dev-esedemo-appgw-pip \
  --query ipAddress
```

### Example API Call
```bash
# Get the IP
APPGW_IP=$(terraform output -raw appgw_public_ip)

# Test the API
curl http://$APPGW_IP/sum?a=5&b=10

# Response:
# {"sum":15}
```

---

## Configuration Details

### Application Gateway Settings

| Setting | Value | Notes |
|---------|-------|-------|
| **SKU Name** | Standard_v2 | Built for AGIC, HTTP/2 support |
| **SKU Tier** | Standard_v2 | Matches SKU name |
| **Capacity** | 2 | Number of instances (min 1, max 125) |
| **Public IP** | Static | No domain needed |
| **Listener Port** | 80, 443 | HTTP/HTTPS capable |
| **Backend Port** | 8080 | Pod service port |

### Subnet Allocation

```
VNet CIDR:     10.0.0.0/16 (65,536 IPs available)
├─ AKS Subnet:   10.0.1.0/24 (256 IPs for nodes/pods)
├─ AppGW Subnet: 10.0.2.0/24 (256 IPs for gateway)
└─ Available:    10.0.3.0/16+ (for future resources)
```

---

## Scaling & Configuration

### Change App Gateway Size

Edit `infra/env/dev/terraform.tfvars`:

```hcl
# For higher traffic
appgw_capacity = 5  # Default is 2

# For WAF (Web Application Firewall) protection
appgw_sku_name = "WAF_v2"
appgw_sku_tier = "WAF_v2"
```

### Change Capacity

```hcl
# Minimum: 1 instance
# Maximum: 125 instances

appgw_capacity = 1  # Minimum cost
appgw_capacity = 5  # Standard production
appgw_capacity = 10 # High traffic
```

---

## Cost Implications

### Application Gateway Pricing

| Component | Cost |
|-----------|------|
| **App Gateway (v2)** | ~$0.25/hour = ~$180/month |
| **Public IP** | ~$3/month |
| **Data Processing** | $0.005/GB processed |
| **Total (base)** | ~$183/month |

### vs Kubernetes Ingress
- **Ingress**: Lower cost, managed within AKS
- **App Gateway**: Higher cost, more features (WAF, SSL offload, etc.)

---

## Advantages of This Setup

✅ **IP-Only Access**
- No domain names required
- More secure (no DNS spoofing)
- Easier for internal networks

✅ **Dedicated Gateway**
- Separate from AKS control plane
- Scales independently
- Better for multi-tenant scenarios

✅ **Advanced Features**
- Web Application Firewall (optional)
- SSL/TLS termination
- URL-based routing
- Host-based routing
- Rate limiting

✅ **Better Control**
- Fine-grained traffic rules
- Backend health monitoring
- Connection draining
- Request timeouts and retries

---

## AGIC (Application Gateway Ingress Controller)

### What is AGIC?
- Watches Kubernetes Ingress resources
- Automatically updates Application Gateway config
- Runs as a pod in AKS cluster

### Note: AGIC is Optional
- In this setup, Ingress is **disabled** (`enabled: false`)
- Application Gateway is managed by **Terraform**
- You could enable Ingress later and use both

### Enable AGIC (Optional)

If you want Kubernetes Ingress + Application Gateway:

1. Enable in Helm `values.yaml`:
```yaml
ingress:
  enabled: true
  className: azure-application-gateway
  hosts:
    - host: "" # Leave empty for IP-only
      paths:
        - path: /
          pathType: Prefix
```

2. Install AGIC add-on in AKS (Terraform would need update)

---

## Troubleshooting

### Issue: Can't connect to API via public IP

**Check if App Gateway is healthy:**
```bash
# Get App Gateway status
az network application-gateway show \
  --name dev-esedemo-appgw \
  --resource-group dev-esedemo-rg \
  --query provisioningState
```

**Check backend pool health:**
```bash
# View backend health
az network application-gateway probe \
  --list \
  --gateway-name dev-esedemo-appgw \
  --resource-group dev-esedemo-rg
```

**Verify service is accessible:**
```bash
# Connect to AKS and test directly
az aks get-credentials --resource-group dev-esedemo-rg --name dev-esedemo-aks
kubectl port-forward svc/python-api 8080:80
curl http://localhost:8080/sum?a=1&b=2
```

### Issue: Pods not in backend pool

**Verify pod is running:**
```bash
kubectl get pods -o wide
```

**Check service endpoints:**
```bash
kubectl get svc python-api
kubectl get endpoints python-api
```

**Check App Gateway logs:**
```bash
az monitor diagnostic-settings create \
  --name appgw-diagnostics \
  --resource dev-esedemo-appgw \
  --workspace /subscriptions/.../resourcegroups/.../providers/microsoft.operationalinsights/workspaces/...
```

---

## Next Steps

1. ✅ Update Terraform variables if needed
2. ✅ Run pipeline: `terraform apply`
3. ✅ Get public IP: `terraform output appgw_public_ip`
4. ✅ Test API: `curl http://<IP>/sum?a=1&b=2`
5. ✅ Configure any additional routing rules
6. ⏳ Add WAF rules if needed
7. ⏳ Setup monitoring and alerting

---

## Commands Reference

```bash
# Get App Gateway public IP
terraform output appgw_public_ip

# Test API endpoint
curl http://$(terraform output -raw appgw_public_ip)/sum?a=1&b=2

# View App Gateway config
az network application-gateway show \
  --name dev-esedemo-appgw \
  --resource-group dev-esedemo-rg \
  --output table

# Check backend pool
az network application-gateway address-pool show \
  --gateway-name dev-esedemo-appgw \
  --name backend-address-pool \
  --resource-group dev-esedemo-rg

# Monitor App Gateway
az monitor metrics list \
  --resource /subscriptions/.../resourceGroups/dev-esedemo-rg/providers/Microsoft.Network/applicationGateways/dev-esedemo-appgw
```

---

## Related Documentation

- [Azure Application Gateway Documentation](https://learn.microsoft.com/en-us/azure/application-gateway/)
- [Application Gateway Ingress Controller (AGIC)](https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview)
- [Azure Application Gateway Configuration](https://learn.microsoft.com/en-us/azure/application-gateway/configuration-overview)
- [Application Gateway Monitoring](https://learn.microsoft.com/en-us/azure/application-gateway/monitor-application-gateway)

---

*Updated for IP-only access with Azure Application Gateway - February 27, 2026*
