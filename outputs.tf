output "security_group_id" {
  description = "The ID of the security group for the GitLab Runner"
  value       = aws_security_group.gitlab_runner.id
}

output "launch_template_id" {
  description = "The ID of the launch template for the GitLab Runner"
  value       = aws_launch_template.gitlab_runner.id
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group for the GitLab Runner"
  value       = aws_autoscaling_group.gitlab_runner.name
}
