{
  "containerDefinitions": [
    {
      "name": "${container_name}",
      "image": "${container_image}",
      "cpu": "${container_cpu}",
      "memory": "${container_memory}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": "${container_port}",
          "hostPort": "${container_port}",
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${log_group}",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "family": "${family_name}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${task_cpu}",
  "memory": "${task_memory}",
  "executionRoleArn": "${execution_role_arn}"
}