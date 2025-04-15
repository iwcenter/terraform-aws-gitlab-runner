terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.86"
    }
  }

  required_version = ">= 1.2.0"
}

resource "aws_security_group" "gitlab_runner" {
  name        = "gitlab-runner-sg"
  description = "Security group for GitLab Runner"
  vpc_id      = "${var.vpc_id}"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "gitlab-runner-sg"
  }
}

resource "aws_launch_template" "gitlab_runner" {
  name_prefix   = "gitlab-runner-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.gitlab_runner.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update and install Docker
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io

    # Install GitLab Runner
    curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
    apt-get install -y gitlab-runner=${var.gitlab_runner_version}

    # make sure gitlab-runner can use docker
    sudo usermod -aG docker gitlab-runner

    # Register the runner
    gitlab-runner register \
      --non-interactive \
      --url "${var.gitlab_url}" \
      --token "${var.runner_authentication_token}" \
      --executor "shell" \
      --description "EC2 Runner (shell)"
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "gitlab-runner"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "gitlab_runner" {
  name                = "gitlab-runner-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.gitlab_runner.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "GitLab Runner"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
