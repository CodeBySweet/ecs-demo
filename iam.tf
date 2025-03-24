# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach the AmazonECSTaskExecutionRolePolicy to the role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom Policy for ECR Access
resource "aws_iam_role_policy" "ecr_access" {
  name = "ECRAccessPolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:StartImageScan",
        "ecr:ListImages",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository",
        "ecr:DeleteRepository",
        "ecr:TagResource"
      ]
      Resource = "*"
    }]
  })
}

# Policy for CloudWatch Logs Access (ECS Task Execution Role)
resource "aws_iam_role_policy" "cloudwatch_logs_access" {
  name = "CloudWatchLogsAccessPolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams" # Optional, if needed
        ]
        Resource = "*"
      }
    ]
  })
}

# Additional Permissions for ECS (if needed)
resource "aws_iam_role_policy" "ecs_access" {
  name = "ECSAccessPolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecs:DescribeClusters",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RunTask",
        "ecs:StartTask",
        "ecs:StopTask",
        "ecs:UpdateService"
      ]
      Resource = "*"
    }]
  })
}

# Additional Permissions for Secrets Manager (if needed)
resource "aws_iam_role_policy" "secrets_manager_access" {
  name = "SecretsManagerAccessPolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "*"
    }]
  })
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "AWSCodePipelineServiceRole-us-east-1-docker-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for CodePipeline (with ECR and CodeConnections permissions)
resource "aws_iam_policy" "codepipeline_policy" {
  name = "AWSCodePipelineServicePolicy-us-east-1-docker-deploy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:ListBuilds",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketLocation"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:RegisterTaskDefinition",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:UpdateTaskSet",
          "iam:PassRole"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection",
          "codestar-connections:GetConnection",
          "codestar-connections:PassConnection"
        ],
        Resource = "arn:aws:codeconnections:us-east-1:626635421987:connection/f11ac47e-d6ab-46a5-9432-d0c7614d3b23"
      }
    ]
  })
}

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# Additional Policy for ECR DescribeRepositories
resource "aws_iam_role_policy" "ecr_describe_repositories" {
  name = "ECRDescribeRepositoriesPolicy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:DescribeRepositories"
        ]
        Resource = "arn:aws:ecr:us-east-1:626635421987:repository/my-app-repo"
      }
    ]
  })
}

# Add a new policy for CloudWatch Logs Access to CodePipeline Role
resource "aws_iam_role_policy" "codepipeline_logs_access" {
  name = "CodePipelineCloudWatchLogsAccessPolicy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for Grafana
resource "aws_iam_role" "grafana_role" {
  name = "grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach a policy to allow Grafana to interact with CloudWatch
resource "aws_iam_role_policy" "grafana_cloudwatch_policy" {
  name = "grafana-cloudwatch-policy"
  role = aws_iam_role.grafana_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach a policy to allow Grafana to interact with CloudWatch Logs
resource "aws_iam_role_policy" "grafana_logs_policy" {
  name = "grafana-logs-policy"
  role = aws_iam_role.grafana_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}