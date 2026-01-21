# Environment Templates Standardization Guide

## 1. Naming Convention Standards

### General Pattern
```
{environment}-{project}-{service}-{resource-type}-{identifier}
```

### Components
- **environment**: `dev`, `staging`, `prod`, `qa`
- **project**: Short project code (e.g., `webapp`, `api`, `data`)
- **service**: Service name (e.g., `frontend`, `backend`, `database`)
- **resource-type**: AWS resource abbreviation
- **identifier**: Optional unique identifier or region

### Resource Type Abbreviations

| Resource | Abbreviation | Example |
|----------|--------------|---------|
| VPC | `vpc` | `prod-webapp-vpc-01` |
| Subnet | `sn` | `prod-webapp-sn-public-1a` |
| Security Group | `sg` | `prod-api-sg-web` |
| EC2 Instance | `ec2` | `prod-backend-ec2-app-01` |
| EKS Cluster | `eks` | `prod-platform-eks-main` |
| ECS Cluster | `ecs` | `prod-microservices-ecs-cluster` |
| ECS Service | `svc` | `prod-api-svc-orders` |
| Load Balancer | `alb/nlb` | `prod-webapp-alb-public` |
| RDS Instance | `rds` | `prod-backend-rds-postgres` |
| S3 Bucket | `s3` | `prod-webapp-s3-assets` |
| IAM Role | `role` | `prod-ecs-role-task-execution` |
| CloudWatch Log Group | `log` | `/aws/prod/api/application` |

### Tag Standards
All resources must include these tags:

```hcl
tags = {
  Environment  = var.environment
  Project      = var.project_name
  ManagedBy    = "Terraform"
  CostCenter   = var.cost_center
  Owner        = var.owner_email
  Service      = var.service_name
  CreatedDate  = timestamp()
}
```

---

## 2. Standard Input Variables

### Common Variables (All Templates)

```hcl
# variables.tf - Common Variables

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

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
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
variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
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
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Must be a valid CloudWatch log retention period."
  }
}
```

### VM-Based Architecture Specific Variables

```hcl
# VM-specific variables

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (leave empty for latest Amazon Linux 2)"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "user_data_script" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}
```

### EKS-Specific Variables

```hcl
# EKS-specific variables

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    instance_types  = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    labels         = map(string)
    taints         = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {
    general = {
      instance_types = ["t3.medium"]
      min_size      = 1
      max_size      = 3
      desired_size  = 2
      disk_size     = 50
      labels        = {}
      taints        = []
    }
  }
}

variable "enable_cluster_autoscaler" {
  description = "Enable Kubernetes Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "enable_aws_load_balancer_controller" {
  description = "Install AWS Load Balancer Controller"
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
```

### ECS (Fargate & EC2) Specific Variables

```hcl
# ECS-specific variables

variable "launch_type" {
  description = "ECS launch type (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "Launch type must be FARGATE or EC2."
  }
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 512
}

variable "container_definitions" {
  description = "Container definitions for ECS task"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 60
}

# EC2 Launch Type Specific
variable "ec2_instance_type" {
  description = "Instance type for ECS EC2 launch type"
  type        = string
  default     = "t3.medium"
}

variable "ec2_min_size" {
  description = "Minimum EC2 instances for ECS cluster"
  type        = number
  default     = 1
}

variable "ec2_max_size" {
  description = "Maximum EC2 instances for ECS cluster"
  type        = number
  default     = 3
}
```

---

## 3. Standard Output Values

### Common Outputs (All Templates)

```hcl
# outputs.tf - Common Outputs

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID where resources are deployed"
  value       = var.vpc_id
}

output "resource_tags" {
  description = "Common tags applied to resources"
  value       = local.common_tags
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.main.name
}
```

### VM-Based Outputs

```hcl
output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.main.name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.main.arn
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.main.id
}

output "security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.instance.id
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "load_balancer_arn" {
  description = "Load balancer ARN"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.main.arn
}

output "instance_role_arn" {
  description = "IAM role ARN for EC2 instances"
  value       = aws_iam_role.instance.arn
}
```

### EKS Outputs

```hcl
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "node_group_ids" {
  description = "Map of node group IDs"
  value       = { for k, v in aws_eks_node_group.main : k => v.id }
}

output "cluster_role_arn" {
  description = "IAM role ARN for EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
```

### ECS Outputs

```hcl
output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "service_id" {
  description = "ECS service ID"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.main.arn
}

output "task_execution_role_arn" {
  description = "IAM role ARN for task execution"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "IAM role ARN for tasks"
  value       = aws_iam_role.task.arn
}

output "security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "service_url" {
  description = "Service URL (load balancer DNS)"
  value       = "http://${aws_lb.main.dns_name}"
}

# For EC2 launch type
output "container_instances_asg_name" {
  description = "Auto Scaling Group name for ECS container instances"
  value       = var.launch_type == "EC2" ? aws_autoscaling_group.ecs[0].name : null
}
```

---

## 4. Environment Variables Standards

### File Structure
Each template should include `.env.template` files for each environment:

```
environments/
├── dev.tfvars
├── staging.tfvars
├── prod.tfvars
└── qa.tfvars
```

### Example: dev.tfvars

```hcl
# dev.tfvars - Development Environment

# General Configuration
environment   = "dev"
project_name  = "webapp"
aws_region    = "us-east-1"
owner_email   = "devteam@example.com"
cost_center   = "engineering-dev"

# Network Configuration
vpc_id              = "vpc-xxxxx"
private_subnet_ids  = ["subnet-xxxxx", "subnet-yyyyy"]
public_subnet_ids   = ["subnet-aaaaa", "subnet-bbbbb"]

# Monitoring
enable_cloudwatch_logs = true
log_retention_days     = 7

# VM-Specific (if using VM template)
instance_type    = "t3.small"
min_size         = 1
max_size         = 2
desired_capacity = 1
key_pair_name    = "dev-webapp-key"

# EKS-Specific (if using EKS template)
cluster_version = "1.28"
node_groups = {
  general = {
    instance_types = ["t3.small"]
    min_size      = 1
    max_size      = 2
    desired_size  = 1
    disk_size     = 30
    labels        = { "workload" = "general" }
    taints        = []
  }
}

# ECS-Specific (if using ECS template)
launch_type    = "FARGATE"
task_cpu       = 256
task_memory    = 512
desired_count  = 1
```

### Example: prod.tfvars

```hcl
# prod.tfvars - Production Environment

# General Configuration
environment   = "prod"
project_name  = "webapp"
aws_region    = "us-east-1"
owner_email   = "platform@example.com"
cost_center   = "engineering-prod"

# Network Configuration
vpc_id              = "vpc-prod-xxxxx"
private_subnet_ids  = ["subnet-prod-1a", "subnet-prod-1b", "subnet-prod-1c"]
public_subnet_ids   = ["subnet-prod-pub-1a", "subnet-prod-pub-1b"]

# Monitoring
enable_cloudwatch_logs = true
log_retention_days     = 90

# VM-Specific (if using VM template)
instance_type    = "t3.large"
min_size         = 3
max_size         = 10
desired_capacity = 5
key_pair_name    = "prod-webapp-key"

# EKS-Specific (if using EKS template)
cluster_version = "1.28"
node_groups = {
  general = {
    instance_types = ["t3.large"]
    min_size      = 3
    max_size      = 10
    desired_size  = 5
    disk_size     = 100
    labels        = { "workload" = "general" }
    taints        = []
  }
  compute = {
    instance_types = ["c5.xlarge"]
    min_size      = 2
    max_size      = 8
    desired_size  = 3
    disk_size     = 100
    labels        = { "workload" = "compute-intensive" }
    taints        = []
  }
}

# ECS-Specific (if using ECS template)
launch_type    = "FARGATE"
task_cpu       = 1024
task_memory    = 2048
desired_count  = 5
```

---

## 5. Validation Rules

### Terraform Validation Module

```hcl
# validation.tf - Input Validation

locals {
  # Validate naming conventions
  name_regex = "^[a-z0-9-]+$"
  
  # Validate environment
  valid_environments = ["dev", "staging", "prod", "qa"]
  
  # Common tags that must be present
  required_tags = ["Environment", "Project", "ManagedBy", "Owner", "CostCenter"]
}

# Custom validation checks
resource "null_resource" "validate_naming" {
  lifecycle {
    precondition {
      condition     = can(regex(local.name_regex, var.project_name))
      error_message = "Project name must only contain lowercase letters, numbers, and hyphens."
    }
  }
}

resource "null_resource" "validate_environment" {
  lifecycle {
    precondition {
      condition     = contains(local.valid_environments, var.environment)
      error_message = "Environment must be one of: ${join(", ", local.valid_environments)}."
    }
  }
}
```

---

## 6. Usage Examples

### Deploying VM Environment

```bash
# Initialize Terraform
terraform init

# Plan with dev environment
terraform plan -var-file=environments/dev.tfvars

# Apply
terraform apply -var-file=environments/dev.tfvars

# Outputs
terraform output
```

### Deploying EKS Environment

```bash
# Deploy to production
terraform apply -var-file=environments/prod.tfvars

# Get kubeconfig
aws eks update-kubeconfig --region us-east-1 --name prod-webapp-eks-main

# Verify
kubectl get nodes
```

### Deploying ECS Environment

```bash
# Deploy staging environment
terraform apply -var-file=environments/staging.tfvars

# Get service URL
terraform output service_url
```

---

## 7. Checklist for Template Compliance

- [ ] All resources follow naming convention: `{env}-{project}-{service}-{type}-{id}`
- [ ] All required input variables are defined with descriptions and validation
- [ ] All required output values are defined with descriptions
- [ ] Common tags are applied to all resources
- [ ] Environment-specific `.tfvars` files exist for dev, staging, prod
- [ ] CloudWatch logging is configured
- [ ] Security groups follow least-privilege principle
- [ ] IAM roles have appropriate policies
- [ ] Module documentation includes usage examples
- [ ] Validation rules enforce standards
- [ ] Sensitive outputs are marked as `sensitive = true`

