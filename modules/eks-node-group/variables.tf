# modules/eks-node-group/variables.tf

variable "cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for EKS worker nodes"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs where nodes will run"
  type        = list(string)
  
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type for nodes"
  type        = string
  default     = "t3.medium"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}