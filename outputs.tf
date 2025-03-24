# Output subnet IDs for debugging
output "subnet_ids" {
  value = data.aws_subnets.existing_subnets.ids
}

output "ecr_repository_url" {
  value = aws_ecr_repository.my_repo.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.my_cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.my_service.name
}