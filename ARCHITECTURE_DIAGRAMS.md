# Azure CI/CD Architecture Diagrams

## 1. High-Level System Architecture

```mermaid
graph TB
    subgraph GitHub["GitHub Repository"]
        Code["Source Code<br/>main.py, Dockerfile"]
        Infra["Infrastructure Code<br/>Terraform/Helm"]
    end
    
    subgraph AzDO["Azure DevOps"]
        Pipeline["Azure Pipelines<br/>azure-pipelines.yml"]
    end
    
    subgraph Build["Build Stage"]
        Test["Run Tests<br/>pytest"]
        DockerBuild["Build Docker<br/>Image"]
        Push["Push to<br/>Registry"]
    end
    
    subgraph Deploy["Deploy Stage"]
        TF["Terraform<br/>Provision"]
        GetCreds["Get AKS<br/>Credentials"]
        Helm["Helm<br/>Deploy"]
    end
    
    subgraph Azure["Azure Cloud"]
        ACR["Azure Container<br/>Registry"]
        AKS["AKS Cluster<br/>Kubernetes"]
        VNET["Virtual<br/>Network"]
        AppInsights["Application<br/>Insights"]
    end
    
    GitHub -->|Trigger| Pipeline
    Pipeline -->|Build| Build
    Build -->|Test| Test
    Test -->|Build| DockerBuild
    DockerBuild -->|Push| Push
    
    Pipeline -->|Deploy| Deploy
    Deploy -->|Provision| TF
    TF -->|Create| Azure
    Deploy -->|Get Creds| GetCreds
    GetCreds -->|Deploy| Helm
    Helm -->|Target| AKS
    
    Push -->|Store| ACR
    Infra -->|Code| TF
    
    AKS -.->|Telemetry| AppInsights
```

## 2. Build Pipeline Detail

```mermaid
graph LR
    A["Commit<br/>main/develop"]
    B["Trigger<br/>Pipeline"]
    C["Python 3.11<br/>Environment"]
    D["Install<br/>Requirements"]
    E["Run pytest<br/>Tests"]
    F["Build<br/>Docker Image"]
    G["Tag Image<br/>build-id"]
    H["Push to<br/>ACR"]
    I["Success?<br/>✓"]
    
    A -->|on commit| B
    B -->|Setup| C
    C -->|Install deps| D
    D -->|Run tests| E
    E -->|Success| F
    F -->|Tag| G
    G -->|Push| H
    H -->|Complete| I
    
    style E fill:#90EE90
    style H fill:#87CEEB
    style I fill:#FFD700
```

## 3. Deploy Pipeline to AKS

```mermaid
graph LR
    A["Terraform<br/>Init"]
    B["Plan<br/>Changes"]
    C["Apply<br/>Resources"]
    D["AKS Created"]
    E["Get<br/>Credentials"]
    F["Update Helm<br/>Values"]
    G["Install/Upgrade<br/>Release"]
    H["Verify<br/>Rollout"]
    I["Success<br/>✓"]
    
    A -->|Backend config| B
    B -->|tfvars| C
    C -->|Creates| D
    D -->|Authenticated| E
    E -->|Update image tag| F
    F -->|Apply| G
    G -->|Check status| H
    H -->|Healthy| I
    
    style D fill:#FFB6C1
    style G fill:#DDA0DD
    style I fill:#FFD700
```

## 4. Kubernetes Cluster Architecture

```mermaid
graph TB
    subgraph AKS["AKS Cluster"]
        subgraph NS["default namespace"]
            Ingress["Ingress<br/>python-api"]
            Service["Service<br/>python-api:80"]
            
            subgraph Deploy["Deployment<br/>python-api"]
                Pod1["Pod 1<br/>python-api:8080"]
                Pod2["Pod 2<br/>python-api:8080"]
                PodN["Pod N<br/>python-api:8080"]
            end
            
            HPA["HPA<br/>2-5 replicas<br/>80% CPU"]
        end
        
        Network["Network Plugin<br/>Azure CNI"]
        Identity["Managed Identity<br/>ACR Pull"]
    end
    
    ACR["Azure Container<br/>Registry"]
    User["User<br/>Request"]
    
    User -->|HTTP/HTTPS| Ingress
    Ingress -->|Route| Service
    Service -->|Load Balance| Deploy
    Deploy -.->|Scale| HPA
    Deploy -->|Pull Image| ACR
    Identity -.->|Auth| ACR
    
    style Pod1 fill:#90EE90
    style Pod2 fill:#90EE90
    style Service fill:#87CEEB
    style HPA fill:#FFB6C1
```

## 5. Infrastructure as Code Structure

```mermaid
graph TB
    Main["main.tf<br/>Root Module"]
    
    Main -->|calls| ACR_Module["modules/acr<br/>Container Registry"]
    Main -->|calls| Network_Module["modules/network<br/>VNet + Subnet"]
    Main -->|calls| AKS_Module["modules/aks<br/>Kubernetes Cluster"]
    Main -->|calls| AppInsights_Module["modules/appinsights<br/>Monitoring"]
    
    Vars["variables.tf<br/>Variable Definitions"]
    TFVars["env/dev/<br/>terraform.tfvars<br/>Environment Values"]
    
    Main -->|reads| Vars
    Main -->|uses| TFVars
    
    ACR_Module -->|creates| ACR_Resource["✓ Container Registry<br/>✓ Scope Map"]
    Network_Module -->|creates| Network_Resource["✓ Virtual Network<br/>✓ Subnet<br/>✓ Service Endpoints"]
    AKS_Module -->|creates| AKS_Resource["✓ AKS Cluster<br/>✓ Node Pool<br/>✓ Managed Identity<br/>✓ Role Assignment"]
    AppInsights_Module -->|creates| AppInsights_Resource["✓ Application Insights<br/>✓ Instrumentation Key"]
    
    style Main fill:#FFE4B5
    style ACR_Module fill:#FFB6C1
    style Network_Module fill:#87CEEB
    style AKS_Module fill:#DDA0DD
    style AppInsights_Module fill:#F0E68C
```

## 6. Helm Chart Structure

```mermaid
graph TB
    Chart["Chart.yaml<br/>Metadata<br/>version: 0.1.0"]
    Values["values.yaml<br/>Default Configuration"]
    
    Templates["templates/"]
    
    Templates -->|_helpers.tpl| Helpers["Template Helpers<br/>fullname, labels, selectors"]
    Templates -->|deployment.yaml| Deployment["Deployment<br/>containers, probes, resources"]
    Templates -->|service.yaml| Service["Service<br/>ClusterIP, port mapping"]
    Templates -->|ingress.yaml| Ingress["Ingress<br/>Domain, TLS, routing"]
    Templates -->|hpa.yaml| HPA["HPA<br/>Auto-scaling rules"]
    
    Deployment -->|uses| Values
    Service -->|uses| Values
    Ingress -->|uses| Values
    HPA -->|uses| Values
    
    Helpers -.->|referenced by| Deployment
    Helpers -.->|referenced by| Service
    Helpers -.->|referenced by| Ingress
    
    style Chart fill:#FFE4B5
    style Values fill:#F0E68C
    style Templates fill:#DDA0DD
```

## 7. Data Flow - From Commit to Running Pod

```mermaid
graph LR
    A["Developer<br/>Commits"]
    B["GitHub<br/>Webhook"]
    C["Azure Pipelines<br/>Triggered"]
    D["Build Agent<br/>Pool"]
    E["Test Code"]
    F["Build Image<br/>esedemo:123"]
    G["Push to ACR"]
    H["Terraform<br/>Applies"]
    I["Helm<br/>Install"]
    J["Kubernetes<br/>Scheduler"]
    K["Pull Image<br/>from ACR"]
    L["Run Pod<br/>python-api:8080"]
    M["Service Routes<br/>Traffic"]
    N["Application<br/>Processes<br/>Request"]
    
    A -->|push| B
    B -->|notify| C
    C -->|dispatch| D
    D -->|execute| E
    E -->|success| F
    F -->|upload| G
    G -->|ready| H
    H -->|infrastructure| I
    I -->|manifest| J
    J -->|schedule| K
    K -->|authenticated| L
    L -->|healthy| M
    M -->|route| N
    
    style A fill:#90EE90
    style F fill:#FFB6C1
    style G fill:#87CEEB
    style L fill:#90EE90
    style N fill:#FFD700
```

## 8. Pipeline Variables Flow

```mermaid
graph TB
    AzDevOps["Azure DevOps<br/>Variables Group<br/>azure-cicd"]
    
    AzDevOps -->|AZURE_SUBSCRIPTION_ID| Pipeline["Pipeline<br/>Configuration"]
    AzDevOps -->|ACR_REGISTRY_URL| Pipeline
    AzDevOps -->|ACR_USERNAME| Pipeline
    AzDevOps -->|ACR_PASSWORD| Pipeline
    AzDevOps -->|AKS_RESOURCE_GROUP| Pipeline
    AzDevOps -->|AKS_CLUSTER_NAME| Pipeline
    AzDevOps -->|TF_STATE_RG| Pipeline
    AzDevOps -->|TF_STATE_STORAGE| Pipeline
    
    Pipeline -->|Environment| BuildStage["Build Stage<br/>Docker Push"]
    Pipeline -->|Environment| DeployStage["Deploy Stage<br/>Terraform & Helm"]
    
    BuildStage -->|Authentication| ACR["Azure Container<br/>Registry"]
    DeployStage -->|Backend Config| TFState["Terraform State<br/>Storage"]
    DeployStage -->|Cluster| AKS["AKS Cluster"]
    
    style AzDevOps fill:#FFE4B5
    style Pipeline fill:#DDA0DD
    style ACR fill:#FFB6C1
    style AKS fill:#87CEEB
```

## 9. Deployment Timeline

```
Day 1: Setup Week
├─ Azure DevOps project creation      [1 hour]
├─ Service connections                [30 min]
├─ Terraform state storage            [15 min]
└─ Pipeline variables                 [15 min]

First Run: Infrastructure (15-20 min)
├─ Tests run                          [2 min]
├─ Docker image build                 [3 min]
├─ Push to ACR                        [1 min]
├─ Terraform init/plan                [2 min]
├─ Terraform apply (AKS creation)     [10-15 min] ⏱️
├─ Get AKS credentials                [1 min]
├─ Helm deploy                        [2 min]
└─ Rollout verification               [1 min]

Subsequent Runs: (2-5 min)
├─ Tests run                          [2 min]
├─ Docker image build & push          [2 min]
├─ Terraform apply (if changed)       [varies]
├─ Helm upgrade                       [1 min]
└─ Rollout verification               [1 min]
```

## 10. Network Architecture

```mermaid
graph TB
    Internet["Internet"]
    AppGW["Application Gateway<br/>(optional)"]
    Ingress["Ingress Controller<br/>Service: python-api"]
    
    subgraph VNET["Virtual Network<br/>10.0.0.0/16"]
        subgraph AKS_Subnet["AKS Subnet<br/>10.0.1.0/24"]
            Node1["Node 1<br/>kubelet"]
            Node2["Node 2<br/>kubelet"]
            
            subgraph Pods["Pods"]
                P1["Pod 1<br/>8080"]
                P2["Pod 2<br/>8080"]
            end
        end
    end
    
    Internet -->|HTTPS:443| AppGW
    AppGW -->|Port 80| Ingress
    Ingress -->|Service| Node1
    Ingress -->|Service| Node2
    Node1 -->|CNI| P1
    Node2 -->|CNI| P2
    
    style VNET fill:#E0F0FF
    style AKS_Subnet fill:#D4E8FF
    style Pods fill:#90EE90
```

---

These diagrams illustrate:
1. **Overall System** - How all components interact
2. **Build Process** - Testing and Docker image creation
3. **Deployment Process** - AKS provisioning and Helm deployment
4. **Kubernetes Architecture** - Pods, services, and ingress
5. **Infrastructure Code** - Terraform module organization
6. **Helm Structure** - Kubernetes manifests management
7. **Data Flow** - From commit to running application
8. **Configuration** - How variables flow through pipeline
9. **Timeline** - Expected execution times
10. **Networking** - Cloud networking architecture
