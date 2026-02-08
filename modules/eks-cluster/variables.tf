# modules/eks-cluster/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "OM-SE-Cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (2 required)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "database_private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (2 required)"
  type        = list(string)
  default     = ["10.0.3.0/24" , "10.0.4.0/24"]
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.0.0/24"
}