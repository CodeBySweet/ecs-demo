terraform {
  backend "s3" {
    bucket = "my-ecs-deploy"
    key    = "ecs_demo/terraform/terraform.tfstate"
    region = "us-east-1"
  }
}