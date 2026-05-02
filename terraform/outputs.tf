output "ecs_cluster_name" {
  description = "ECS cluster name for aws ecs update-service --cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name for aws ecs update-service --service"
  value       = aws_ecs_service.main.name
}

output "ecs_service_arn" {
  description = "Full ARN of the ECS service (IAM policy scope)."
  value       = aws_ecs_service.main.arn
}

output "github_actions_role_arn" {
  description = "Pass to GitHub Variable GITHUB_ACTIONS_ROLE_ARN or build role-to-assume in deploy.yml."
  value       = aws_iam_role.github_actions.arn
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ECS service."
  value       = module.vpc.public_subnets
}
