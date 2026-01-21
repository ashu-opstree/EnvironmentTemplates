# ============================================================================
# AWS VM Environment - Development Configuration
# ============================================================================

environment   = "dev"
project_name  = "webapp"
aws_region    = "us-east-1"
owner_email   = "devteam@example.com"
cost_center   = "engineering-dev"

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

vpc_id             = "vpc-xxxxx"
private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
public_subnet_ids  = ["subnet-aaaaa", "subnet-bbbbb"]

# ============================================================================
# COMPUTE CONFIGURATION (VM-Specific from multicloud.md)
# ============================================================================

instance_type = "t3.small"  # AWS small instance (from multicloud.md mapping)
ami_id        = ""          # Leave empty to use latest Amazon Linux 2
key_pair_name = ""          # Optional - SSM Session Manager preferred for security

# ============================================================================
# AUTO SCALING CONFIGURATION
# ============================================================================

min_size         = 1   # Minimum instances (multicloud.md: min_instances = 1)
max_size         = 2   # Maximum instances (multicloud.md: max_instances = 2)
desired_capacity = 1   # Desired instances (multicloud.md: desired_instances = 1)

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

root_volume_size = 30  # OS disk size in GB (multicloud.md: os_disk_size_gb = 30)

# ============================================================================
# APPLICATION CONFIGURATION
# ============================================================================

application_port = 8080
health_check_path = "/health"

# Optional: Custom user data script
# user_data_script = ""

# ============================================================================
# MONITORING & LOGGING (from multicloud.md)
# ============================================================================

enable_cloudwatch_logs = true
log_retention_days     = 7   # Reduced for dev environment (multicloud.md example: 7 days)
enable_monitoring      = true

# ============================================================================
# ADDITIONAL TAGS (from multicloud.md tag standards)
# ============================================================================

tags = {
  Team          = "Platform"
  Service       = "webapp"
  CloudProvider = "aws"
  ManagedBy     = "Terraform"
}

