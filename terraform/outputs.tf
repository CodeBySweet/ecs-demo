output "ecs_cluster_name" {
  value = aws_ecs_cluster.my_cluster.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.my_repo.repository_url
}

# output "ecs_service_name" {
#   value = aws_ecs_service.my_service.name
# }

output "ecr_repository_name" {
  value = aws_ecr_repository.my_repo.name
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

# output "task_definition" {
#   value     = local_file.task_definition.content
#   sensitive = true
# }
