# ============================================================================
# AWS VM-Based Environment Module - Outputs
# ============================================================================

# ============================================================================
# GENERAL OUTPUTS
# ============================================================================

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

# ============================================================================
# AUTO SCALING GROUP OUTPUTS
# ============================================================================

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.main.name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_id" {
  description = "Auto Scaling Group ID"
  value       = aws_autoscaling_group.main.id
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.main.latest_version
}

# ============================================================================
# LOAD BALANCER OUTPUTS
# ============================================================================

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "load_balancer_arn" {
  description = "Load balancer ARN"
  value       = aws_lb.main.arn
}

output "load_balancer_zone_id" {
  description = "Load balancer zone ID"
  value       = aws_lb.main.zone_id
}

output "load_balancer_url" {
  description = "Load balancer URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "Target group name"
  value       = aws_lb_target_group.main.name
}

# ============================================================================
# SECURITY GROUP OUTPUTS
# ============================================================================

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "instance_security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.instance.id
}

# ============================================================================
# IAM OUTPUTS
# ============================================================================

output "instance_role_arn" {
  description = "IAM role ARN for EC2 instances"
  value       = aws_iam_role.instance.arn
}

output "instance_role_name" {
  description = "IAM role name for EC2 instances"
  value       = aws_iam_role.instance.name
}

output "instance_profile_arn" {
  description = "IAM instance profile ARN"
  value       = aws_iam_instance_profile.main.arn
}

output "instance_profile_name" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.main.name
}

# ============================================================================
# MONITORING OUTPUTS
# ============================================================================

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.main[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.main[0].arn : null
}

output "scale_up_alarm_arn" {
  description = "CloudWatch alarm ARN for scale up"
  value       = aws_cloudwatch_metric_alarm.high_cpu.arn
}

output "scale_down_alarm_arn" {
  description = "CloudWatch alarm ARN for scale down"
  value       = aws_cloudwatch_metric_alarm.low_cpu.arn
}

# ============================================================================
# SUMMARY OUTPUT
# ============================================================================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment              = var.environment
    project_name            = var.project_name
    region                  = var.aws_region
    load_balancer_url       = "http://${aws_lb.main.dns_name}"
    autoscaling_group_name  = aws_autoscaling_group.main.name
    min_instances           = var.min_size
    max_instances           = var.max_size
    desired_instances       = var.desired_capacity
    instance_type           = var.instance_type
  }
}