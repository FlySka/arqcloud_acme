terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "leccion4-compute"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Leccion     = "4"
    }
  }
}

# ── Data sources ──────────────────────────────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── SERVICIO 1: EC2 con Auto Scaling Group ────────────────────────────────────
module "ec2_asg" {
  source = "./modules/ec2-asg"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = data.aws_vpc.default.id
  subnet_ids   = data.aws_subnets.default.ids
  ami_id       = data.aws_ami.amazon_linux_2023.id
  # t2.micro → Free Tier (750 horas/mes)
  instance_type    = "t2.micro"
  min_size         = 1
  max_size         = 3
  desired_capacity = 1
}

# ── SERVICIO 2: ECS Fargate ───────────────────────────────────────────────────
module "ecs_fargate" {
  source = "./modules/ecs-fargate"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = data.aws_vpc.default.id
  subnet_ids   = data.aws_subnets.default.ids
  # Imagen pública de demo (nginx)
  container_image = "public.ecr.aws/nginx/nginx:stable"
  # 256 CPU + 512 MB → mínimo Fargate (AWS Academy cubre el costo)
  container_cpu    = 256
  container_memory = 512
  desired_count    = 1
}

# ── SERVICIO 3: Lambda ────────────────────────────────────────────────────────
module "lambda" {
  source = "./modules/lambda"

  project_name = var.project_name
  environment  = var.environment
  # Free Tier: 1M invocaciones/mes y 400.000 GB-segundos gratis
  memory_size = 128
  timeout     = 10
}
