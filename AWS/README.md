# AWS Environment Modules - Complete Implementation Guide

## Overview

This repository contains three production-ready Terraform modules for deploying complete infrastructure environments on AWS:

1. **VM-Based Architecture** - Auto Scaling Groups with EC2 instances
2. **Kubernetes (EKS)** - Managed Kubernetes clusters with node groups
3. **Containers (ECS)** - Fargate and EC2 launch types for containerized applications

All modules follow the standardization guide for naming conventions, inputs, outputs, and best practices.

---

## Directory Structure

```
terraform-aws-modules/
├── modules/
│   ├── vm-environment/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── user_data.sh
│   ├── eks-environment/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── iam_policies/
│   │   │   └── aws_load_balancer_controller.json
│   └── ecs-environment/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── vm.tfvars
│   │   ├── eks.tfvars
│   │   └── ecs-fargate.tfvars
│   ├── staging/
│   │   ├── vm.tfvars
│   │   ├── eks.tfvars
│   │   └── ecs-fargate.tfvars
│   └── prod/
│       ├── vm.tfvars
│       ├── eks.tfvars
│       ├── ecs-fargate.tfvars
│       └── ecs-ec2.tfvars
├── examples/
│   ├── vm-simple/
│   ├── eks-simple/
│   └── ecs-fargate/
└── README.md
```

---

## Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured
- Existing VPC with public and private subnets

### 1. VM-Based Environment

```bash
cd examples/vm-simple
terraform init
terraform plan -var-file=../../environments/dev/vm.tfvars
terraform apply -var-file=../../environments/dev/vm.tfvars
```

### 2. EKS Environment

```bash
cd examples/eks-simple
terraform init
terraform plan -var-file=../../environments/dev/eks.tfvars
terraform apply -var-file=../../environments/dev/eks.tfvars

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name dev-myproject-eks
```

### 3. ECS Environment (Fargate)

```bash
cd examples/ecs-fargate
terraform init
terraform plan -var-file=../../environments/dev/ecs-fargate.tfvars
terraform apply -var-file=../../environments/dev/ecs-fargate.tfvars
```

---

## Module 1: VM-Based Environment

### Features

- Auto Scaling Group with configurable min/max/desired capacity
- Application Load Balancer with health checks
- CloudWatch Logs and Metrics
- Auto scaling policies based on CPU utilization
- SSM Session Manager for secure access
- Encrypted EBS volumes
- IMDSv2 enforced for security

### Example Usage

```hcl
module "vm_environment" {
  source = "./modules/vm-environment"

  # Required
  environment        = "dev"
  project_name       = "webapp"
  aws_region         = "us-east-1"
  vpc_id             = "vpc-xxxxx"
  private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
  public_subnet_ids  = ["subnet-aaaaa", "subnet-bbbbb"]
  owner_email        = "devteam@example.com"
  cost_center        = "engineering"

  # Optional
  instance_type     = "t3.medium"
  min_size          = 2
  max_size          = 6
  desired_capacity  = 3
  application_port  = 8080
  health_check_path = "/health"

  tags = {
    Team = "Platform"
  }
}
```

### Outputs

```hcl
# Access the load balancer URL
output "app_url" {
  value = module.vm_environment.load_balancer_url
}

# Auto Scaling Group name
output "asg_name" {
  value = module.vm_environment.autoscaling_group_name
}
```

---

## Module 2: EKS Environment

### Features

- Managed EKS cluster with configurable Kubernetes version
- Multiple node groups with different instance types and configurations
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Cluster Autoscaler IAM role and configuration
- AWS Load Balancer Controller IAM role
- VPC CNI, CoreDNS, and kube-proxy add-ons
- CloudWatch Logs for control plane
- Support for both public and private endpoints

### Example Usage

```hcl
module "eks_environment" {
  source = "./modules/eks-environment"

  # Required
  environment        = "prod"
  project_name       = "platform"
  aws_region         = "us-east-1"
  vpc_id             = "vpc-xxxxx"
  private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy", "subnet-zzzzz"]
  public_subnet_ids  = ["subnet-aaaaa", "subnet-bbbbb"]
  owner_email        = "platform@example.com"
  cost_center        = "engineering"

  # Cluster Configuration
  cluster_version                 = "1.28"
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Node Groups
  node_pools = {
    general = {
      instance_types = ["t3.large"]
      min_nodes      = 2
      max_nodes      = 10
      desired_nodes  = 3
      disk_size_gb   = 100
      capacity_type  = "ON_DEMAND"
      labels         = {
        workload = "general"
      }
      taints = []
    }
    
    spot = {
      instance_types = ["t3.large", "t3a.large"]
      min_nodes      = 0
      max_nodes      = 5
      desired_nodes  = 2
      disk_size_gb   = 50
      capacity_type  = "SPOT"
      labels         = {
        workload = "batch"
      }
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NoSchedule"
        }
      ]
    }
  }

  # Features
  enable_cluster_autoscaler           = true
  enable_aws_load_balancer_controller = true
  enable_ebs_csi_driver              = true

  tags = {
    Team = "Platform"
  }
}
```

### Post-Deployment Steps

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name prod-platform-eks

# Verify cluster
kubectl get nodes
kubectl get pods -A

# Install Cluster Autoscaler (if enabled)
kubectl apply -f cluster-autoscaler.yaml

# Install AWS Load Balancer Controller (if enabled)
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=prod-platform-eks \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<ROLE_ARN>
```

### Outputs

```hcl
# Cluster endpoint and credentials
output "cluster_endpoint" {
  value     = module.eks_environment.cluster_endpoint
  sensitive = true
}

# kubectl configuration command
output "configure_kubectl" {
  value = module.eks_environment.kubeconfig_command
}
```

---

## Module 3: ECS Environment

### Features

- Support for both Fargate and EC2 launch types
- Application Load Balancer with target groups
- Task and execution IAM roles
- Auto scaling for both tasks and EC2 instances
- CloudWatch Logs for containers
- ECS Exec support for debugging
- Container Insights for monitoring
- Secrets Manager and Parameter Store integration

### Example Usage - Fargate

```hcl
module "ecs_fargate" {
  source = "./modules/ecs-environment"

  # Required
  environment        = "prod"
  project_name       = "api"
  aws_region         = "us-east-1"
  vpc_id             = "vpc-xxxxx"
  private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
  public_subnet_ids  = ["subnet-aaaaa", "subnet-bbbbb"]
  owner_email        = "api-team@example.com"
  cost_center        = "engineering"
  container_image    = "123456789.dkr.ecr.us-east-1.amazonaws.com/api:v1.2.3"

  # Fargate Configuration
  launch_type     = "FARGATE"
  task_cpu        = 1024
  task_memory     = 2048
  container_port  = 8080
  
  # Scaling
  desired_count   = 4
  min_count       = 2
  max_count       = 10

  # Application Configuration
  environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "info"
    PORT        = "8080"
  }

  secrets = {
    DATABASE_URL = "arn:aws:secretsmanager:us-east-1:123456789:secret:prod/database-url"
    API_KEY      = "arn:aws:ssm:us-east-1:123456789:parameter/prod/api-key"
  }

  health_check_path           = "/health"
  health_check_grace_period   = 60
  enable_execute_command      = true
  enable_container_insights   = true

  tags = {
    Team = "Backend"
  }
}
```

### Example Usage - EC2 Launch Type

```hcl
module "ecs_ec2" {
  source = "./modules/ecs-environment"

  # Required
  environment        = "prod"
  project_name       = "worker"
  aws_region         = "us-east-1"
  vpc_id             = "vpc-xxxxx"
  private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
  public_subnet_ids  = ["subnet-aaaaa", "subnet-bbbbb"]
  owner_email        = "workers@example.com"
  cost_center        = "engineering"
  container_image    = "123456789.dkr.ecr.us-east-1.amazonaws.com/worker:latest"

  # EC2 Launch Type
  launch_type       = "EC2"
  task_memory       = 1024
  container_port    = 8080
  
  # Task Scaling
  desired_count     = 10
  min_count         = 5
  max_count         = 20

  # EC2 Instance Configuration
  ec2_instance_type     = "c5.xlarge"
  ec2_min_size          = 3
  ec2_max_size          = 10
  ec2_desired_capacity  = 5

  environment_variables = {
    WORKER_TYPE = "batch-processor"
  }

  tags = {
    Team = "Data"
  }
}
```

### Outputs

```hcl
# Service URL
output "service_url" {
  value = module.ecs_fargate.service_url
}

# Cluster details
output "cluster_name" {
  value = module.ecs_fargate.cluster_name
}
```

---

## Environment Variable Files

### dev/vm.tfvars

```hcl
environment   = "dev"
project_name  = "webapp"
aws_region    = "us-east-1"
owner_email   = "devteam@example.com"
cost_center   = "engineering-dev"

vpc_id             = "vpc-xxxxx"
private_subnet_ids = ["subnet-private-1", "subnet-private-2"]
public_subnet_ids  = ["subnet-public-1", "subnet-public-2"]

instance_type    = "t3.small"
min_size         = 1
max_size         = 3
desired_capacity = 2
application_port = 8080

enable_cloudwatch_logs = true
log_retention_days     = 7
```

### prod/eks.tfvars

```hcl
environment   = "prod"
project_name  = "platform"
aws_region    = "us-east-1"
owner_email   = "platform@example.com"
cost_center   = "engineering-prod"

vpc_id             = "vpc-prod-xxxxx"
private_subnet_ids = ["subnet-prod-private-1a", "subnet-prod-private-1b", "subnet-prod-private-1c"]
public_subnet_ids  = ["subnet-prod-public-1a", "subnet-prod-public-1b"]

cluster_version                 = "1.28"
cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true

node_pools = {
  general = {
    instance_types = ["m5.xlarge"]
    min_nodes      = 3
    max_nodes      = 15
    desired_nodes  = 5
    disk_size_gb   = 100
    capacity_type  = "ON_DEMAND"
    labels         = { workload = "general" }
    taints         = []
  }
  
  compute = {
    instance_types = ["c5.2xlarge"]
    min_nodes      = 2
    max_nodes      = 10
    desired_nodes  = 3
    disk_size_gb   = 100
    capacity_type  = "ON_DEMAND"
    labels         = { workload = "compute-intensive" }
    taints         = []
  }
}

enable_cluster_autoscaler           = true
enable_aws_load_balancer_controller = true
enable_cluster_logs                 = true
log_retention_days                  = 90
```

### prod/ecs-fargate.tfvars

```hcl
environment   = "prod"
project_name  = "api"
aws_region    = "us-east-1"
owner_email   = "api@example.com"
cost_center   = "engineering-prod"

vpc_id             = "vpc-prod-xxxxx"
private_subnet_ids = ["subnet-prod-private-1a", "subnet-prod-private-1b"]
public_subnet_ids  = ["subnet-prod-public-1a", "subnet-prod-public-1b"]

launch_type     = "FARGATE"
container_image = "123456789.dkr.ecr.us-east-1.amazonaws.com/api:v1.0.0"
task_cpu        = 2048
task_memory     = 4096
container_port  = 8080

desired_count = 6
min_count     = 3
max_count     = 15

environment_variables = {
  ENVIRONMENT = "production"
  LOG_LEVEL   = "info"
}

health_check_path         = "/health"
health_check_grace_period = 120
enable_execute_command    = false
enable_container_insights = true
log_retention_days        = 90
```

---

## Best Practices

### 1. Naming Conventions

All resources follow the pattern: `{environment}-{project}-{resource-type}-{identifier}`

Examples:
- `prod-webapp-vpc-01`
- `dev-api-eks-main`
- `staging-worker-ecs-cluster`

### 2. Tagging Strategy

Every resource includes:
- Environment
- Project
- ManagedBy: "Terraform"
- Owner
- CostCenter
- CloudProvider: "aws"

### 3. Security

- All EBS volumes are encrypted
- IMDSv2 enforced on EC2 instances
- Private subnets for compute resources
- Security groups follow least-privilege principle
- SSM Session Manager instead of SSH
- ECS Exec only enabled when needed

### 4. High Availability

- Minimum 2 availability zones
- Auto Scaling Groups for resilience
- Health checks on all services
- Multi-AZ deployment for production

### 5. Monitoring

- CloudWatch Logs enabled by default
- Metrics and alarms for auto scaling
- Container Insights for ECS
- Proper log retention policies

### 6. Cost Optimization

- Use Spot instances for non-critical workloads
- Appropriate instance sizing
- Auto scaling to match demand
- Different configurations per environment

---

## Deployment Workflow

### Development Environment

```bash
# 1. Plan changes
terraform plan -var-file=environments/dev/vm.tfvars -out=dev.tfplan

# 2. Review plan
terraform show dev.tfplan

# 3. Apply
terraform apply dev.tfplan

# 4. Verify
terraform output
```

### Production Environment

```bash
# 1. Create a new workspace
terraform workspace new prod

# 2. Plan with prod variables
terraform plan -var-file=environments/prod/eks.tfvars -out=prod.tfplan

# 3. Get approval (manual step)
# Review plan, get sign-off from team

# 4. Apply during maintenance window
terraform apply prod.tfplan

# 5. Validate deployment
terraform output deployment_summary
```

---

## Troubleshooting

### VM Module Issues

**Problem**: Instances not registering with load balancer

**Solution**:
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Check target group health
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Check instance logs
aws logs tail /aws/ec2/dev-webapp --follow
```

### EKS Module Issues

**Problem**: Nodes not joining cluster

**Solution**:
```bash
# Check node IAM role
aws iam get-role --role-name dev-platform-eks-node-role

# View node group status
aws eks describe-nodegroup --cluster-name dev-platform-eks --nodegroup-name general

# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### ECS Module Issues

**Problem**: Tasks failing to start

**Solution**:
```bash
# View service events
aws ecs describe-services --cluster dev-api-ecs --services dev-api-ecs-service

# Check task logs
aws logs tail /aws/ecs/dev-api-ecs --follow

# Describe stopped tasks
aws ecs describe-tasks --cluster dev-api-ecs --tasks <task-id>
```

---

## Maintenance and Updates

### Updating Module Versions

```hcl
# Use version constraints
module "vm_environment" {
  source  = "git::https://github.com/your-org/terraform-aws-modules.git//modules/vm-environment?ref=v1.2.0"
  # ... configuration
}
```

### Updating Kubernetes Version

```bash
# 1. Update cluster
terraform apply -var='cluster_version="1.29"'

# 2. Update node groups (one at a time)
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets
# Terraform will create new nodes
kubectl delete node <old-node-name>
```

### Updating ECS Task Definitions

```bash
# 1. Build and push new image
docker build -t api:v1.1.0 .
docker tag api:v1.1.0 123456789.dkr.ecr.us-east-1.amazonaws.com/api:v1.1.0
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/api:v1.1.0

# 2. Update variable
terraform apply -var='container_image="123456789.dkr.ecr.us-east-1.amazonaws.com/api:v1.1.0"'
```
