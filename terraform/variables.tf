variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k8s-the-hard-way"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "key_name" {
  description = "AWS Key Pair name for EC2 instances"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.240.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.240.0.0/24"
}

variable "pod_cidr_blocks" {
  description = "CIDR blocks for pod networking on each worker node"
  type        = list(string)
  default     = ["10.200.0.0/24", "10.200.1.0/24"]
}

variable "cluster_service_cidr" {
  description = "CIDR block for cluster services"
  type        = string
  default     = "10.32.0.0/24"
}