variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

# Security Group Ports
variable "sg_ports" {
  description = "Security Group's Ports"
  type = list(number)
  default = [80, 443, 5000]
}

variable "grafana_anonymous_enabled" {
  description = "Enable anonymous access to Grafana"
  type        = bool
  default     = true
}

variable "grafana_anonymous_org_role" {
  description = "Organization role for anonymous users in Grafana"
  type        = string
  default     = "Admin"
}

variable "grafana_aws_profiles" {
  description = "AWS profile name for Grafana"
  type        = string
  default     = "default"
}

variable "grafana_aws_access_key" {
  description = "AWS access key for Grafana"
  type        = string
  sensitive   = true
}

variable "grafana_aws_secret_key" {
  description = "AWS secret key for Grafana"
  type        = string
  sensitive   = true
}

variable "grafana_aws_region" {
  description = "AWS region for Grafana"
  type        = string
  default     = "us-east-1"
}