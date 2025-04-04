# Reference the existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-047a90672a7b63ceb"
}

# Reference the existing subnets
data "aws_subnets" "existing_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
}

# Create a security group for the application
resource "aws_security_group" "my_sg" {
  name        = "my-app-sg"
  description = "Security group for my ECS service"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each = toset([for port in var.sg_ports : tostring(port)])

  type              = "ingress"
  description       = "Allow traffic on port ${each.value}"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.my_sg.id
}

# Create a security group for Grafana
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-sg"
  description = "Security group for Grafana"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # Allow inbound HTTP traffic for Grafana
  ingress {
    description = "Allow Grafana traffic"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from anywhere (for testing)
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Declare the ECR repository for the application
resource "aws_ecr_repository" "my_repo" {
  name                 = "my-app-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Local variables
locals {
  subnets           = data.aws_subnets.existing_subnets.ids
  security_groups   = [aws_security_group.my_sg.id]
  app_image_url     = "${aws_ecr_repository.my_repo.repository_url}:latest"
  grafana_image_url = "grafana/grafana:latest"
  my_app_dns_name   = "${aws_ecs_service.my_service.name}.${aws_ecs_service.my_service.cluster}.local"
}

# Your secret name in Secrets Manager
data "aws_secretsmanager_secret" "account_id" {
  name = account_id
}

data "aws_secretsmanager_secret_version" "account_id" {
  secret_id = data.aws_secretsmanager_secret.account_id.id
}

locals {
  account_id = jsondecode(data.aws_secretsmanager_secret_version.account_id.secret_string)["account_id"]
}

# Create an ECS task definition for the application
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "my-app-container"
      image     = "${local.account_id}.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:latest"
      cpu       = 1024
      memory    = 4096
      essential = true

      portMappings = [
        {
          containerPort = 5000 # Flask app endpoint
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.my_app_log_group.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }

      # Health check configuration
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f --max-time 2 http://localhost:5000/health || exit 1"]
        interval    = 15
        retries     = 5
        startPeriod = 180
        timeout     = 10
      }
    }
  ])
}


# Create an ECS cluster with Container Insights enabled
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-app-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "my-app-alb-sg"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "my-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = ["subnet-0859bd81a92ddf92b", "subnet-07094ff379a1fe8ac"]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "my-app-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.existing_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Create an ECS service for the application
resource "aws_ecs_service" "my_service" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.subnets
    security_groups  = local.security_groups
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "my-app-container"
    container_port   = 5000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.my_app.arn
  }

  depends_on = [aws_lb_listener.http]
}

# Output ALB DNS name
output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

resource "local_file" "task_definition" {
  filename = "${path.root}/task-definition.json"
  content = jsonencode({
    family                  = aws_ecs_task_definition.my_task.family
    executionRoleArn        = aws_ecs_task_definition.my_task.execution_role_arn
    taskRoleArn             = aws_ecs_task_definition.my_task.task_role_arn
    networkMode             = aws_ecs_task_definition.my_task.network_mode
    requiresCompatibilities = aws_ecs_task_definition.my_task.requires_compatibilities
    cpu                     = aws_ecs_task_definition.my_task.cpu
    memory                  = aws_ecs_task_definition.my_task.memory
    containerDefinitions    = jsondecode(aws_ecs_task_definition.my_task.container_definitions)
  })
}


output "container_definitions" {
  description = "The container definitions for the ECS task"
  value       = aws_ecs_task_definition.my_task.container_definitions
  sensitive   = true
}

# CloudWatch Alarm for High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = ["arn:aws:sns:us-east-1:${local.account_id}:my-sns-topic"]
  dimensions = {
    ClusterName = aws_ecs_cluster.my_cluster.name
    ServiceName = aws_ecs_service.my_service.name
  }
}

# CloudWatch Dashboard for ECS CPU Utilization
resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "ecs-cpu-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ServiceName",
              aws_ecs_service.my_service.name,
              "ClusterName",
              aws_ecs_cluster.my_cluster.name
            ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "ECS CPU Utilization for my-app-service"
        }
      }
    ]
  })
}

# Create the CloudWatch Logs log group for the application
resource "aws_cloudwatch_log_group" "my_app_log_group" {
  name              = "/ecs/my-app-task"
  retention_in_days = 30
}

# Update Grafana Task Definition to use the Grafana IAM Role and public image
resource "aws_ecs_task_definition" "grafana_task" {
  family                   = "grafana-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = aws_iam_role.grafana_role.arn
  task_role_arn            = aws_iam_role.grafana_role.arn

  container_definitions = jsonencode([{
    name      = "grafana"
    image     = local.grafana_image_url
    cpu       = 1024
    memory    = 3072
    essential = true

    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.monitoring_log_group.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "grafana"
      }
    }

    environment = [
      {
        name  = "GF_AUTH_ANONYMOUS_ENABLED",
        value = var.grafana_anonymous_enabled ? "true" : "false"
      },
      {
        name  = "GF_AUTH_ANONYMOUS_ORG_ROLE",
        value = var.grafana_anonymous_org_role
      },
      {
        name  = "GF_AWS_default_REGION",
        value = var.grafana_aws_region
      },
      {
        name  = "GF_AWS_AUTH_ENABLED",
        value = "true"
      },
      {
        name  = "GF_AWS_EC2_IAM_ROLE_ARN",
        value = aws_iam_role.grafana_role.arn
      },
      {
        name  = "GF_AWS_ALLOWED_AUTH_PROVIDERS",
        value = "default"
      },
      {
        name  = "GF_AWS_ASSUME_ROLE_ENABLED",
        value = "true"
      }
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
      interval    = 30
      retries     = 3
      startPeriod = 60
      timeout     = 5
    }
  }])
}

# Create an ECS service for Grafana
resource "aws_ecs_service" "grafana_service" {
  name            = "grafana-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.grafana_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.subnets
    security_groups  = [aws_security_group.monitoring_sg.id]
    assign_public_ip = true
  }

  # Enable service discovery for Grafana
  service_registries {
    registry_arn = aws_service_discovery_service.grafana.arn
  }
}

# Create a CloudWatch Logs log group for monitoring
resource "aws_cloudwatch_log_group" "monitoring_log_group" {
  name              = "/ecs/monitoring"
  retention_in_days = 30
}

# Service Discovery for Grafana
resource "aws_service_discovery_service" "grafana" {
  name = "grafana"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.my_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Service Discovery for Flask App
resource "aws_service_discovery_service" "my_app" {
  name = "my-app"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.my_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Private DNS namespace for service discovery
resource "aws_service_discovery_private_dns_namespace" "my_namespace" {
  name        = "my-namespace.local"
  description = "Private DNS namespace for Grafana and Flask App"
  vpc         = data.aws_vpc.existing_vpc.id
}