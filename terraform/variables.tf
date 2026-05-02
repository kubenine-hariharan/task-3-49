variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
}

variable "dockerhub_image" {
  description = "Full Docker Hub image reference (e.g. myuser/flask-app:latest). Push this image before first apply."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in owner/name form for OIDC trust (e.g. myorg/task-3-49)."
  type        = string
}
