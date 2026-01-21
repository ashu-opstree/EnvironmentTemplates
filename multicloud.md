# Multi-Cloud Environment Templates Standardization Guide

## 1. Naming Convention Standards

### General Pattern
```
{environment}-{project}-{service}-{resource-type}-{identifier}
```

### Components
- **environment**: `dev`, `staging`, `prod`, `qa`
- **project**: Short project code (e.g., `webapp`, `api`, `data`)
- **service**: Service name (e.g., `frontend`, `backend`, `database`)
- **resource-type**: Cloud resource abbreviation
- **identifier**: Optional unique identifier or region

### Resource Type Abbreviations (Multi-Cloud)

| Resource | AWS | Azure | GCP | Generic Abbr |
|----------|-----|-------|-----|--------------|
| Virtual Network | `vpc` | `vnet` | `vpc` | `net` |
| Subnet | `sn` | `snet` | `subnet` | `sn` |
| Security Group | `sg` | `nsg` | `fw` | `sg` |
| Virtual Machine | `ec2` | `vm` | `gce` | `vm` |
| Kubernetes Cluster | `eks` | `aks` | `gke` | `k8s` |
| Container Service | `ecs` | `aci/aca` | `cloudrun` | `container` |
| Load Balancer | `alb/nlb` | `lb` | `lb` | `lb` |
| Database Instance | `rds` | `sqldb` | `cloudsql` | `db` |
| Object Storage | `s3` | `storage` | `gcs` | `storage` |
| IAM Role | `role` | `role` | `sa` | `role` |
| Log Workspace | `log` | `law` | `log` | `log` |
| Key Vault | `kms` | `kv` | `kms` | `vault` |

### Naming Examples by Cloud

**AWS:**
```
prod-webapp-vpc-01
prod-api-sg-web
prod-backend-ec2-app-01
prod-platform-eks-main
```

**Azure:**
```
prod-webapp-vnet-01
prod-api-nsg-web
prod-backend-vm-app-01
prod-platform-aks-main
```

**GCP:**
```
prod-webapp-vpc-01
prod-api-fw-web
prod-backend-gce-app-01
prod-platform-gke-main
```

### Tag/Label Standards
All resources must include these tags/labels:

```hcl
# Terraform format (works for all clouds)
tags = {
  Environment  = var.environment
  Project      = var.project_name
  ManagedBy    = "Terraform"
  CostCenter   = var.cost_center
  Owner        = var.owner_email
  Service      = var.service_name
  CloudProvider = var.cloud_provider
  CreatedDate  = timestamp()
}
```

---

## 2. Standard Input Variables

### Common Variables (All Templates, All Clouds)

```hcl
# variables.tf - Common Variables

variable "cloud_provider" {
  description = "Cloud provider (aws, azure, gcp)"
  type        = string
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be aws, azure, or gcp."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod, qa)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "qa"], var.environment)
    error_message = "Environment must be dev, staging, prod, or qa."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "Cloud region for resource deployment"
  type        = string
  # Examples: us-east-1 (AWS), eastus (Azure), us-central1 (GCP)
}

variable "tags" {
  description = "Additional tags/labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "owner_email" {
  description = "Email of the resource owner"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
}

# Network Configuration
variable "network_id" {
  description = "Network ID where resources will be deployed (VPC/VNet/VPC ID)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
  default     = []
}

# Monitoring & Logging
variable "enable_logging" {
  description = "Enable cloud-native logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}
```

### VM-Based Architecture Specific Variables

```hcl
# VM-specific variables (multi-cloud compatible)

variable "instance_type" {
  description = "Instance/VM size"
  type        = string
  # AWS: t3.medium, Azure: Standard_D2s_v3, GCP: e2-medium
}

variable "image_id" {
  description = "OS image ID or reference"
  type        = string
  default     = ""
  # AWS: AMI ID, Azure: Image reference, GCP: Image family
}

variable "ssh_key" {
  description = "SSH public key or key pair name for VM access"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of instances in scaling group"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances in scaling group"
  type        = number
  default     = 3
}

variable "desired_instances" {
  description = "Desired number of instances in scaling group"
  type        = number
  default     = 2
}

variable "boot_script" {
  description = "Initialization script for VM startup"
  type        = string
  default     = ""
  # AWS: user_data, Azure: custom_data, GCP: startup-script
}

variable "os_disk_size_gb" {
  description = "OS/root disk size in GB"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "List of availability zones for VM distribution"
  type        = list(string)
  default     = []
}
```

### Kubernetes-Specific Variables (EKS/AKS/GKE)

```hcl
# Kubernetes-specific variables

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_pools" {
  description = "Map of node pool/group configurations"
  type = map(object({
    instance_types  = list(string)
    min_nodes      = number
    max_nodes      = number
    desired_nodes  = number
    disk_size_gb   = number
    labels         = map(string)
    taints         = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {
    general = {
      instance_types = ["medium"]  # Cloud-agnostic sizing
      min_nodes     = 1
      max_nodes     = 3
      desired_nodes = 2
      disk_size_gb  = 50
      labels        = {}
      taints        = []
    }
  }
}

variable "enable_autoscaling" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = true
}

variable "enable_load_balancer_controller" {
  description = "Install native load balancer controller"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to cluster endpoint"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable Kubernetes network policies"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable container insights/monitoring"
  type        = bool
  default     = true
}
```

### Container Service Specific Variables (ECS/ACI/Cloud Run)

```hcl
# Container service-specific variables

variable "container_runtime" {
  description = "Container runtime type (serverless/dedicated)"
  type        = string
  default     = "serverless"
  # AWS: FARGATE/EC2, Azure: serverless/dedicated, GCP: fully-managed/GKE
  validation {
    condition     = contains(["serverless", "dedicated"], var.container_runtime)
    error_message = "Container runtime must be serverless or dedicated."
  }
}

variable "container_cpu" {
  description = "CPU units for the container (in millicores: 256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "container_memory_mb" {
  description = "Memory for the container in MB"
  type        = number
  default     = 512
}

variable "container_image" {
  description = "Container image URL"
  type        = string
  # Format: registry/image:tag
}

variable "container_port" {
  description = "Container port to expose"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Desired number of container instances"
  type        = number
  default     = 2
}

variable "enable_exec" {
  description = "Enable container exec/ssh for debugging"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 60
}

variable "environment_variables" {
  description = "Environment variables for containers"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret references for containers"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# For dedicated/VM-based container runtime
variable "vm_instance_type" {
  description = "Instance type for dedicated container hosts"
  type        = string
  default     = "medium"
}

variable "vm_min_instances" {
  description = "Minimum VM instances for container cluster"
  type        = number
  default     = 1
}

variable "vm_max_instances" {
  description = "Maximum VM instances for container cluster"
  type        = number
  default     = 3
}
```

---

## 3. Standard Output Values

### Common Outputs (All Templates, All Clouds)

```hcl
# outputs.tf - Common Outputs

output "cloud_provider" {
  description = "Cloud provider"
  value       = var.cloud_provider
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "region" {
  description = "Cloud region"
  value       = var.region
}

output "network_id" {
  description = "Network ID where resources are deployed"
  value       = var.network_id
}

output "resource_tags" {
  description = "Common tags/labels applied to resources"
  value       = local.common_tags
}

output "log_workspace_id" {
  description = "Logging workspace/group ID"
  value       = local.log_workspace_id
}

output "deployment_id" {
  description = "Unique deployment identifier"
  value       = local.deployment_id
}
```

### VM-Based Outputs

```hcl
output "scaling_group_name" {
  description = "Auto scaling group/scale set name"
  value       = local.scaling_group_name
  # AWS: ASG, Azure: VMSS, GCP: MIG
}

output "scaling_group_id" {
  description = "Auto scaling group/scale set ID"
  value       = local.scaling_group_id
}

output "instance_template_id" {
  description = "Instance template/launch template ID"
  value       = local.instance_template_id
}

output "security_group_id" {
  description = "Security group/NSG/firewall rule ID"
  value       = local.security_group_id
}

output "load_balancer_endpoint" {
  description = "Load balancer DNS/IP endpoint"
  value       = local.load_balancer_endpoint
}

output "load_balancer_id" {
  description = "Load balancer ID"
  value       = local.load_balancer_id
}

output "backend_pool_id" {
  description = "Backend pool/target group ID"
  value       = local.backend_pool_id
}

output "instance_role_id" {
  description = "IAM/managed identity ID for instances"
  value       = local.instance_role_id
}

output "instance_ips" {
  description = "List of instance private IPs"
  value       = local.instance_ips
}
```

### Kubernetes Outputs

```hcl
output "cluster_id" {
  description = "Kubernetes cluster ID"
  value       = local.cluster_id
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = local.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes cluster API endpoint"
  value       = local.cluster_endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes cluster version"
  value       = local.cluster_version
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = local.cluster_ca_cert
  sensitive   = true
}

output "node_pool_ids" {
  description = "Map of node pool/group IDs"
  value       = local.node_pool_ids
}

output "cluster_identity_id" {
  description = "Cluster managed identity/service account ID"
  value       = local.cluster_identity_id
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = local.kubectl_config_command
}

output "cluster_resource_group" {
  description = "Resource group containing cluster resources (Azure-specific)"
  value       = var.cloud_provider == "azure" ? local.cluster_rg : null
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = local.oidc_issuer_url
}
```

### Container Service Outputs

```hcl
output "container_cluster_id" {
  description = "Container cluster/service ID"
  value       = local.container_cluster_id
  # AWS: ECS Cluster, Azure: Container Instance/App, GCP: Cloud Run service
}

output "container_cluster_name" {
  description = "Container cluster/service name"
  value       = local.container_cluster_name
}

output "service_id" {
  description = "Container service ID"
  value       = local.service_id
}

output "service_name" {
  description = "Container service name"
  value       = local.service_name
}

output "task_definition_id" {
  description = "Task/container definition ID"
  value       = local.task_definition_id
}

output "execution_role_id" {
  description = "Container execution role/identity ID"
  value       = local.execution_role_id
}

output "task_role_id" {
  description = "Container task role/identity ID"
  value       = local.task_role_id
}

output "security_group_id" {
  description = "Security group/NSG for containers"
  value       = local.security_group_id
}

output "service_endpoint" {
  description = "Service URL/endpoint"
  value       = local.service_endpoint
}

output "load_balancer_endpoint" {
  description = "Load balancer endpoint (if applicable)"
  value       = local.load_balancer_endpoint
}

output "registry_url" {
  description = "Container registry URL"
  value       = local.registry_url
}

# For dedicated/VM-based runtime
output "vm_scaling_group_id" {
  description = "VM scaling group ID for container hosts"
  value       = var.container_runtime == "dedicated" ? local.vm_scaling_group_id : null
}
```

---

## 4. Environment Variables Standards

### File Structure
Each template should include environment-specific variable files:

```
environments/
├── aws/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── azure/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── gcp/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

### Example: AWS dev.tfvars

```hcl
# environments/aws/dev.tfvars

cloud_provider = "aws"
environment    = "dev"
project_name   = "webapp"
region         = "us-east-1"
owner_email    = "devteam@example.com"
cost_center    = "engineering-dev"

# Network
network_id         = "vpc-xxxxx"
private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
public_subnet_ids  = ["subnet-aaaaa", "subnet-bbbbb"]

# Logging
enable_logging     = true
log_retention_days = 7

# VM-Specific
instance_type     = "t3.small"
min_instances     = 1
max_instances     = 2
desired_instances = 1
ssh_key           = "dev-webapp-key"
availability_zones = ["us-east-1a", "us-east-1b"]

# Kubernetes-Specific
cluster_version = "1.28"
node_pools = {
  general = {
    instance_types = ["t3.small"]
    min_nodes     = 1
    max_nodes     = 2
    desired_nodes = 1
    disk_size_gb  = 30
    labels        = { workload = "general" }
    taints        = []
  }
}

# Container-Specific
container_runtime    = "serverless"  # FARGATE
container_cpu        = 256
container_memory_mb  = 512
desired_count        = 1
container_image      = "123456789.dkr.ecr.us-east-1.amazonaws.com/app:latest"
```

### Example: Azure dev.tfvars

```hcl
# environments/azure/dev.tfvars

cloud_provider = "azure"
environment    = "dev"
project_name   = "webapp"
region         = "eastus"
owner_email    = "devteam@example.com"
cost_center    = "engineering-dev"

# Network
network_id         = "/subscriptions/.../virtualNetworks/vnet-dev"
private_subnet_ids = ["/subscriptions/.../subnets/snet-private-1"]
public_subnet_ids  = ["/subscriptions/.../subnets/snet-public-1"]

# Logging
enable_logging     = true
log_retention_days = 7

# VM-Specific
instance_type     = "Standard_B2s"
min_instances     = 1
max_instances     = 2
desired_instances = 1
ssh_key           = "ssh-rsa AAAAB3NzaC1yc2E..."
availability_zones = ["1", "2"]

# Kubernetes-Specific
cluster_version = "1.28"
node_pools = {
  general = {
    instance_types = ["Standard_D2s_v3"]
    min_nodes     = 1
    max_nodes     = 2
    desired_nodes = 1
    disk_size_gb  = 30
    labels        = { workload = "general" }
    taints        = []
  }
}

# Container-Specific
container_runtime    = "serverless"  # Azure Container Instances
container_cpu        = 1
container_memory_mb  = 1024
desired_count        = 1
container_image      = "myregistry.azurecr.io/app:latest"
```

### Example: GCP dev.tfvars

```hcl
# environments/gcp/dev.tfvars

cloud_provider = "gcp"
environment    = "dev"
project_name   = "webapp"
region         = "us-central1"
owner_email    = "devteam@example.com"
cost_center    = "engineering-dev"

# Network
network_id         = "projects/my-project/global/networks/vpc-dev"
private_subnet_ids = ["projects/my-project/regions/us-central1/subnetworks/subnet-private"]
public_subnet_ids  = []

# Logging
enable_logging     = true
log_retention_days = 7

# VM-Specific
instance_type     = "e2-small"
min_instances     = 1
max_instances     = 2
desired_instances = 1
ssh_key           = "devuser:ssh-rsa AAAAB3NzaC1yc2E..."
availability_zones = ["us-central1-a", "us-central1-b"]

# Kubernetes-Specific
cluster_version = "1.28"
node_pools = {
  general = {
    instance_types = ["e2-medium"]
    min_nodes     = 1
    max_nodes     = 2
    desired_nodes = 1
    disk_size_gb  = 30
    labels        = { workload = "general" }
    taints        = []
  }
}

# Container-Specific
container_runtime    = "serverless"  # Cloud Run
container_cpu        = 1
container_memory_mb  = 512
desired_count        = 1
container_image      = "gcr.io/my-project/app:latest"
```

---

## 5. Cloud Provider Mapping Reference

### Instance Types/Sizes

| Category | AWS | Azure | GCP |
|----------|-----|-------|-----|
| Micro | `t3.micro` | `Standard_B1s` | `e2-micro` |
| Small | `t3.small` | `Standard_B2s` | `e2-small` |
| Medium | `t3.medium` | `Standard_D2s_v3` | `e2-medium` |
| Large | `t3.large` | `Standard_D4s_v3` | `e2-standard-4` |
| Compute Optimized | `c5.xlarge` | `Standard_F4s_v2` | `c2-standard-4` |
| Memory Optimized | `r5.xlarge` | `Standard_E4s_v3` | `n2-highmem-4` |

### Kubernetes Services

| Component | AWS | Azure | GCP |
|-----------|-----|-------|-----|
| Service | EKS | AKS | GKE |
| Node Group | Node Groups | Node Pools | Node Pools |
| Version Format | `1.28` | `1.28` | `1.28` |
| Load Balancer Controller | AWS LB Controller | Application Gateway Ingress | GKE Ingress |

### Container Services

| Component | AWS | Azure | GCP |
|-----------|-----|-------|-----|
| Serverless | ECS Fargate | Azure Container Instances / Container Apps | Cloud Run |
| Managed | ECS on EC2 | Azure Container Instances (dedicated) | GKE Autopilot |
| Registry | ECR | ACR | GCR / Artifact Registry |

### Networking

| Component | AWS | Azure | GCP |
|-----------|-----|-------|-----|
| Virtual Network | VPC | Virtual Network | VPC |
| Subnet | Subnet | Subnet | Subnet |
| Security | Security Group | Network Security Group | Firewall Rules |
| Load Balancer | ALB/NLB | Load Balancer | Load Balancer |

---

## 6. Validation Rules

### Multi-Cloud Validation Module

```hcl
# validation.tf - Input Validation

locals {
  # Validate naming conventions
  name_regex = "^[a-z0-9-]+$"
  
  # Validate environment
  valid_environments = ["dev", "staging", "prod", "qa"]
  
  # Validate cloud providers
  valid_providers = ["aws", "azure", "gcp"]
  
  # Common tags that must be present
  required_tags = ["Environment", "Project", "ManagedBy", "Owner", "CostCenter", "CloudProvider"]
  
  # Cloud-specific validations
  valid_aws_regions    = ["us-east-1", "us-east-2", "us-west-1", "us-west-2", "eu-west-1"]
  valid_azure_regions  = ["eastus", "westus", "northeurope", "westeurope"]
  valid_gcp_regions    = ["us-central1", "us-east1", "europe-west1", "asia-east1"]
}

# Validate cloud provider
resource "null_resource" "validate_cloud_provider" {
  lifecycle {
    precondition {
      condition     = contains(local.valid_providers, var.cloud_provider)
      error_message = "Cloud provider must be one of: ${join(", ", local.valid_providers)}."
    }
  }
}

# Validate naming conventions
resource "null_resource" "validate_naming" {
  lifecycle {
    precondition {
      condition     = can(regex(local.name_regex, var.project_name))
      error_message = "Project name must only contain lowercase letters, numbers, and hyphens."
    }
  }
}

# Validate environment
resource "null_resource" "validate_environment" {
  lifecycle {
    precondition {
      condition     = contains(local.valid_environments, var.environment)
      error_message = "Environment must be one of: ${join(", ", local.valid_environments)}."
    }
  }
}

# Cloud-specific region validation
resource "null_resource" "validate_region" {
  lifecycle {
    precondition {
      condition = (
        (var.cloud_provider == "aws" && contains(local.valid_aws_regions, var.region)) ||
        (var.cloud_provider == "azure" && contains(local.valid_azure_regions, var.region)) ||
        (var.cloud_provider == "gcp" && contains(local.valid_gcp_regions, var.region))
      )
      error_message = "Invalid region for the selected cloud provider."
    }
  }
}
```

---

## 7. Usage Examples

### Deploying to AWS

```bash
# Initialize
terraform init

# Select AWS workspace
terraform workspace select aws-dev || terraform workspace new aws-dev

# Plan
terraform plan -var-file=environments/aws/dev.tfvars

# Apply
terraform apply -var-file=environments/aws/dev.tfvars
```

### Deploying to Azure

```bash
# Initialize
terraform init

# Select Azure workspace
terraform workspace select azure-dev || terraform workspace new azure-dev

# Plan
terraform plan -var-file=environments/azure/dev.tfvars

# Apply
terraform apply -var-file=environments/azure/dev.tfvars
```

### Deploying to GCP

```bash
# Initialize
terraform init

# Select GCP workspace
terraform workspace select gcp-dev || terraform workspace new gcp-dev

# Plan
terraform plan -var-file=environments/gcp/dev.tfvars

# Apply
terraform apply -var-file=environments/gcp/dev.tfvars
```

### Multi-Cloud Deployment Script

```bash
#!/bin/bash
# deploy.sh - Deploy to multiple clouds

ENVIRONMENT=$1
CLOUD=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$CLOUD" ]; then
  echo "Usage: ./deploy.sh <environment> <cloud>"
  echo "Example: ./deploy.sh dev aws"
  exit 1
fi

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod|qa)$ ]]; then
  echo "Error: Environment must be dev, staging, prod, or qa"
  exit 1
fi

if [[ ! "$CLOUD" =~ ^(aws|azure|gcp)$ ]]; then
  echo "Error: Cloud must be aws, azure, or gcp"
  exit 1
fi

# Deploy
echo "Deploying to $CLOUD - $ENVIRONMENT environment..."
terraform workspace select ${CLOUD}-${ENVIRONMENT} || terraform workspace new ${CLOUD}-${ENVIRONMENT}
terraform plan -var-file=environments/${CLOUD}/${ENVIRONMENT}.tfvars
terraform apply -var-file=environments/${CLOUD}/${ENVIRONMENT}.tfvars
```

---

## 8. Checklist for Template Compliance

### General Compliance
- [ ] Resources follow naming convention: `{env}-{project}-{service}-{type}-{id}`
- [ ] Cloud provider is clearly specified in variables and tags
- [ ] All required input variables are defined with descriptions and validation
- [ ] All required output values are defined with descriptions
- [ ] Common tags/labels are applied to all resources
- [ ] Environment-specific `.tfvars` files exist for each cloud (aws, azure, gcp)

### Cloud-Specific Compliance
- [ ] Cloud-specific resource naming follows provider conventions
- [ ] Region/location formats match cloud provider requirements
- [ ] Instance/VM sizes use correct naming for each provider
- [ ] Network references use appropriate format (VPC/VNet/VPC)
- [ ] Identity management uses correct service (IAM/Managed Identity/Service Account)

### Functional Compliance
- [ ] Logging is configured using cloud-native services
- [ ] Security groups/NSGs/firewall rules follow least-privilege
- [ ] IAM roles/identities have appropriate policies
- [ ] Module documentation includes multi-cloud usage examples
- [ ] Validation rules enforce standards across all clouds
- [ ] Sensitive outputs are marked as `sensitive = true`

### Documentation
- [ ] README includes cloud-specific deployment instructions
- [ ] Variable descriptions specify cloud-specific formats
- [ ] Examples provided for all three cloud providers
- [ ] Cloud provider mapping reference is included

---

## 9. Next Steps

1. **Review and Approve**: Share this guide with the team for feedback across cloud teams
2. **Create Base Modules**: Build separate modules for each cloud provider (AWS, Azure, GCP)
3. **Abstract Common Logic**: Create a cloud-agnostic wrapper that calls cloud-specific modules
4. **Testing**: Deploy to dev environment in all three clouds and validate
5. **Documentation**: Create cloud-specific README.md files with examples
6. **CI/CD Integration**: Add multi-cloud validation checks to pipeline
7. **Training**: Conduct team walkthrough of standards and multi-cloud deployment
8. **Migration Strategy**: Plan migration path for existing single-cloud deployments

---

## 10. Additional Resources

### Terraform Cloud Provider Documentation
- **AWS**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Azure**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **GCP**: https://registry.terraform.io/providers/hashicorp/google/latest/docs

### Best Practices by Cloud
- **AWS**: Use AWS Well-Architected Framework