variable "gitlab_url" {
  description = "GitLab URL"
  type        = string
  default     = "https://gitlab.com/"
}

variable "runner_authentication_token" {
  description = "GitLab Runner authentication token"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instance"
  type        = string
}

variable "gitlab_runner_version" {
  description = "Version of gitlab runner"
  type        = string
  default     = "17.10.1-1"
}

variable "ami_id" {
  description = "AMI to use"
  type        = string
  default     = "ami-0655cec52acf2717b" # Ubuntu 22.04 AMD64
}

variable "vpc_ic" {
  description = "VPC"
  type        = string
}

variable "subnets" {
  description = "Subnets"
  type        = list(string)
}

variable "oidc_role_attach_policies" {
  description = "Policies to attach to role"
  type        = list(string)
  default     = []
}

variable "project_paths" {
  description = "Projects that authenticate to AWS"
  type        = list(string)
}
