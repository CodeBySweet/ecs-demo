variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "sg_ports" {
  description = "Security Group's Ports"
  type        = list(number)
  default     = [80, 443, 5000, 3000]
}

variable "grafana_anonymous_enabled" {
  description = "Enable anonymous access to Grafana"
  type        = bool
  default     = false
}

variable "grafana_anonymous_org_role" {
  description = "Organization role for anonymous users in Grafana"
  type        = string
  default     = "Viewer"
}

variable "grafana_aws_region" {
  description = "AWS region for Grafana"
  type        = string
  default     = "us-east-1"
}

variable "github_repository" {
  description = "GitHub repository in format 'org/repo' for OIDC trust"
  type        = string
  default     = "your-github-org/your-repo"
}

variable "github_branch" {
  description = "GitHub branch to allow for OIDC trust"
  type        = string
  default     = "main"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "app_desired_count" {
  description = "Number of app tasks to run"
  type        = number
  default     = 1
}

variable "grafana_desired_count" {
  description = "Number of Grafana tasks to run"
  type        = number
  default     = 1
}

variable "sns_topic_arn" {
  description = "ARN for SNS topic for alarms"
  type        = string
  default = "arn:aws:sns:us-east-1:626635421987:ECS_TOPIC"
}

variable "another_variable" {
  description = "Example of another variable"
  type        = string
  default     = "default_value"
}