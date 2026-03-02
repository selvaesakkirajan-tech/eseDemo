# Enhancement Discussion - API Enhancements

**Date:** March 1, 2026  
**Status:** Planning Phase

---

## 📋 Current Architecture Summary

Based on `COMPLETE_SETUP_GUIDE.md`:

- ✅ Python API (Flask) - `/sum?a=1&b=2` endpoint
- ✅ Azure Kubernetes Service (AKS) - `dev-esedemo-aks`
- ✅ Azure Container Registry (ACR) - `esedemo<xxx>`
- ✅ Azure DevOps CI/CD pipeline
- ✅ Terraform + Helm deployment
- ✅ LoadBalancer for public IP exposure
- ✅ SonarCloud code quality checks
- ✅ App Insights monitoring
- ✅ Resource Group: `dev-esedemo-rg`

---

## 🚀 Planned Enhancements

| # | Enhancement | Priority | Status |
|---|-------------|----------|--------|
| 3 | Azure App Gateway (Public Exposure) | High | ⏳ Ready to implement |
| 4 | Azure Key Vault - Store tfvars secrets | High | ⏳ Ready to implement |
| 5 | API Basic Auth (username/password) | High | ⏳ Ready to implement |
| 6 | Cosmos DB (credential store - ~3 rows) | High | ⏳ Ready to implement |
| 1 | Harness (CI/CD) | Medium | ⏸️ ON HOLD |
| 2 | Ansible (Config Mgmt) | Medium | ⏸️ ON HOLD |

---

## ❓ Questions Needing Answers

---

### 🔐 Enhancement 4: Store tfvars in Vault

> **Current state:** Secrets stored in Azure DevOps Variable Group (`azure-cicd`)

#### Questions:

- [ ] **Q4.1** - Which Vault are you targeting?
  - **Option A**: Azure Key Vault *(already in Azure ecosystem, native integration with Azure DevOps)*
  - **Option B**: HashiCorp Vault self-hosted on AKS
  - **Option C**: HCP Vault (HashiCorp Cloud Platform - managed)
  > 💡 *Recommendation: Azure Key Vault - zero extra infra, integrates natively with existing pipeline*
  Agreed

- [ ] **Q4.2** - Which specific tfvars should move to Vault?
  - ACR credentials (`ACR_USERNAME`, `ACR_PASSWORD`)?yes
  - Service Principal secrets (`AZURE_CLIENT_SECRET`)?yes
  - ALL variables from `azure-cicd` variable group?no
  - Only sensitive ones (passwords/secrets)?yes


- [ ] **Q4.3** - How should pipeline fetch secrets?
  - **Option A**: Azure DevOps fetches from Key Vault at pipeline runtime (built-in integration)
  - **Option B**: Terraform fetches directly from Vault during `terraform apply`
  - **Option C**: Both - pipeline fetches for CI, Terraform fetches for CD-this works

- [ ] **Q4.4** - Replace or keep Azure DevOps Variable Group?
  - Full replace - remove `azure-cicd` variable group?no
  - Keep variable group but link it to Key Vault?
  > 💡 *Azure DevOps supports linking Variable Groups directly to Azure Key Vault*

---

### 🔑 Enhancement 5: API Authentication (Username/Password)

> **Current state:** API is open - `http://<IP>/sum?a=1&b=2` - no auth

#### Questions:

- [ ] **Q5.1** - Authentication type?
  - **Option A**: JWT Token - `/login` endpoint returns token, use token in header
  - **Option B**: Basic Auth - username:password in every request header-easy , we can go with this
  - **Option C**: API Key - static key per user
  > 💡 *Recommendation: JWT Token - industry standard, more secure, stateless*

- [ ] **Q5.2** - Which endpoints need protection?
  - Just `/sum`?-this one
  - All endpoints including future ones?
  - Mix - some public, some protected?

- [ ] **Q5.3** - Login flow - do you want a `/login` endpoint?
  - Example: `POST /login` with `{"username":"admin","password":"xxx"}` → returns JWT token
  - Then: `GET /sum?a=1&b=2` with `Authorization: Bearer <token>` header
  -->no, user can access the endpoint sum , popup with user name and password
  and all good then reply with sum. if not access denied.

- [ ] **Q5.4** - Token expiry?
  - Short-lived: 1 hour?
  - Long-lived: 24 hours?yes
  - Refresh token needed?

- [ ] **Q5.5** - User roles needed?
  - All users same access? yes
  - Admin vs readonly roles?

---

### 🗄️ Enhancement 6: Cosmos DB (Credential Storage)

> **Confirmed:** ~3 rows (small user list)

#### Questions:

- [ ] **Q6.1** - What exactly is stored?
  - User list (username + hashed password) only? yes
  - Plus roles (admin/readonly)?no
  - Plus audit log (who accessed when)?no

- [ ] **Q6.2** - Proposed data schema - does this look right?
  ```json
  {
    "id": "user1",
    "username": "user1",
    "password_hash": "<bcrypt-hashed-password>",
    "role": "admin",
    "active": true,
    "created_at": "2026-03-01"
  }
  ```
  - Any fields to add or remove? shoud be fine

- [ ] **Q6.3** - Cosmos DB API type?
  - **Option A**: NoSQL (Core SQL API) *(recommended for this use case)* Yes
  - **Option B**: MongoDB API
  - **Option C**: Table API

- [ ] **Q6.4** - Resource placement?
  - Same RG as AKS: `dev-esedemo-rg`?Yes
  - New dedicated RG?

- [ ] **Q6.5** - Who creates the initial 3 users?
  - Terraform provisioning (seed data)?
  - Python seed script run once after deploy? yes
  - Manual insert via Azure Portal?

- [ ] **Q6.6** - Cosmos DB connection string - where stored?
  - Azure Key Vault (links to Enhancement 4)?yes
  - Azure DevOps Variable Group?

---

### 🔵 Enhancement 1: Harness (CI/CD)

> **Current state:** Azure DevOps pipeline `azure-pipelines.yml`
lets hold all harness as of now
#### Questions:

- [ ] **Q1.1** - Scope of Harness?
  - **Option A**: Full migration - replace Azure DevOps entirely
  - **Option B**: Harness for CD only, keep Azure DevOps for CI (build/test)
  - **Option C**: Run both in parallel (Azure DevOps CI → Harness CD)

- [ ] **Q1.2** - Harness tier?
  - Free tier (limited features)?
  - Harness Cloud (SaaS paid)?
  - Self-hosted Harness on AKS?

- [ ] **Q1.3** - Harness Delegate location?
  - Inside existing AKS cluster?
  - Separate VM?

- [ ] **Q1.4** - Trigger strategy?
  - Git push triggers Harness pipeline?
  - Azure DevOps triggers Harness as downstream?

---

### 🟢 Enhancement 2: Ansible
-lets hold ansible as of now
> **Current state:** Terraform handles infra, Helm handles app deployment

#### Questions:

- [ ] **Q2.1** - What should Ansible manage?
  - AKS node bootstrapping/configuration?
  - Application config management (replace some Helm)?
  - Post-Terraform infrastructure setup?
  - Azure VM configuration (if any VMs added)?

- [ ] **Q2.2** - Where does Ansible run?
  - **Option A**: Inside Azure DevOps pipeline agent
  - **Option B**: Dedicated Ansible control node (VM in Azure)
  - **Option C**: AWX / Ansible Tower (web UI for Ansible)
  - **Option D**: Inside Harness pipeline (if Q1.1 = Harness)

- [ ] **Q2.3** - Ansible inventory type?
  - Dynamic inventory from Azure (auto-discovers resources)?
  - Static inventory file?

- [ ] **Q2.4** - Ansible + Terraform relationship?
  - Terraform provisions → Ansible configures? (most common pattern)
  - Replace some Terraform with Ansible?

---

### 🟠 Enhancement 3: Azure Application Gateway

> **Current state:** Direct LoadBalancer IP: `http://<LOADBALANCER_IP>/sum?a=1&b=2`

#### Questions:

- [ ] **Q3.1** - WAF needed?
  - **Option A**: Standard App Gateway (Standard_v2) - basic routing--Yes
  - **Option B**: App Gateway + WAF_v2 *(recommended for public API - blocks OWASP attacks)*

- [ ] **Q3.2** - Custom domain?
  - Yes - do you have a domain name ready? (e.g., `api.yourdomain.com`)
  - No - use Azure-provided DNS? can we use my customized name.. like paulkani.com .. I want this DNS be setup in azure 

- [ ] **Q3.3** - SSL/TLS certificate?
  - Azure-managed certificate (free, auto-renews)? -Yes
  - Bring your own certificate?
  - Self-signed (dev/test only)?

- [ ] **Q3.4** - AGIC (App Gateway Ingress Controller)?
  - Replace current LoadBalancer with AGIC in AKS?
  - Keep internal LoadBalancer, add App Gateway as external frontend?Yes, lets try above

- [ ] **Q3.5** - Path-based routing needed now or future?
  - Only `/sum` endpoint today? yes
  - Planning to add more microservices routed via URL path?

---

## 📌 Implementation Order (Active)

```
Phase 1 (Foundation):
  ├── Cosmos DB (NoSQL/Core SQL, dev-esedemo-rg) - Terraform
  └── Python seed script (3 users: username + bcrypt password hash)

Phase 2 (API Auth - Basic Auth):
  └── Protect /sum with HTTP Basic Auth
      - Credentials verified against Cosmos DB
      - Browser shows native username/password popup
      - Access denied if wrong credentials

Phase 3 (Security - Azure Key Vault):
  ├── Move ACR_USERNAME, ACR_PASSWORD, AZURE_CLIENT_SECRET to Key Vault
  ├── Keep azure-cicd Variable Group but LINK it to Key Vault
  └── Cosmos DB connection string also stored in Key Vault

Phase 4 (App Gateway):
  ├── Standard App Gateway v2 (Terraform)
  ├── AGIC in AKS - replace current LoadBalancer
  └── Public IP only (no custom domain, no SSL)

--- ON HOLD ---
Phase 5: Ansible
Phase 6: Harness
```

---

## 🔗 Target Architecture Diagram

```
[Developer] → [GitHub Push]
                    ↓
            [Azure DevOps CI]
            Build + Test + SonarCloud
                    ↓
            [ACR - Docker Image]
                    ↓
            [Azure DevOps CD]
            Terraform + Helm
                    ↓
┌─────────────────────────────────────────────────┐
│                AZURE INFRASTRUCTURE              │
│                                                 │
│  [App Gateway Standard_v2]                       │
│   Public IP: http://<APPGW_IP>/sum              │
│          ↓                                      │
│  [AKS Ingress (AGIC)]                           │
│          ↓                                      │
│  [Python API Pod]                               │
│    GET /sum → Basic Auth popup                  │
│              → verify vs Cosmos DB              │
│              → return sum OR 401 denied         │
│          ↓                                      │
│  [Cosmos DB NoSQL]  ← username + password_hash  │
│                                                 │
│  [Azure Key Vault]                              │
│    ACR_USERNAME, ACR_PASSWORD,                  │
│    AZURE_CLIENT_SECRET,                         │
│    COSMOS_DB_CONNECTION_STRING                  │
└─────────────────────────────────────────────────┘
```

---

## ✅ Decisions Log

| # | Topic | Decision | Status |
|---|-------|----------|--------|
| 4.1 | Vault type | Azure Key Vault | ✅ Decided |
| 4.2 | Which secrets to vault | ACR creds + SP secret (sensitive only) | ✅ Decided |
| 4.3 | Pipeline fetch method | Both: DevOps CI + Terraform CD | ✅ Decided |
| 4.4 | Variable Group | Keep, link to Key Vault | ✅ **Done - Phase 2** |
| 5.1 | Auth type | HTTP Basic Auth (browser popup) | ✅ Decided |
| 5.2 | Protected endpoints | `/sum` only | ✅ Decided |
| 5.3 | Login flow | No /login endpoint - Basic Auth popup on /sum | ✅ Decided |
| 5.4 | Session duration | N/A - Basic Auth sends creds each request | ⚠️ See note below |
| 5.5 | User roles | All users same access | ✅ Decided |
| 6.1 | Cosmos DB content | username + password_hash only | ✅ Decided |
| 6.2 | Schema | Simplified (no role field needed) | ✅ Decided |
| 6.3 | Cosmos DB API | NoSQL (Core SQL) | ✅ Decided |
| 6.4 | Cosmos DB placement | dev-esedemo-rg | ✅ Decided |
| 6.5 | Seed users | Python seed script (3 users) | ✅ Decided |
| 6.6 | Connection string | Azure Key Vault | ✅ Decided |
| 3.1 | App Gateway tier | Standard_v2 | ✅ Decided |
| 3.2 | Custom domain | None - use App Gateway public IP directly | ✅ Decided |
| 3.3 | SSL cert | Not needed (no domain = no SSL) | ✅ Decided |
| 3.4 | AGIC | Replace LoadBalancer with AGIC | ✅ Decided |
| 3.5 | Routing | /sum only for now | ✅ Decided |
| 1 | Harness | ON HOLD | ⏸️ Later |
| 2 | Ansible | ON HOLD | ⏸️ Later |

---

## ⚠️ Notes

### Basic Auth - No Token Expiry
HTTP Basic Auth sends username:password with **every request** (browser caches it for the session).
There is no "24-hour expiry" concept in Basic Auth - the browser clears credentials when:
- Browser tab/window is closed
- User explicitly logs out (not straightforward with Basic Auth)

**If session expiry is important → consider upgrading to JWT later.**  
For now, Basic Auth is fine for this use case.

### Domain
No custom domain - API will be accessed via App Gateway public IP directly:  
`http://<APPGW_PUBLIC_IP>/sum?a=1&b=2`

---

*Last updated: March 1, 2026*
