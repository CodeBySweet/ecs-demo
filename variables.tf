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