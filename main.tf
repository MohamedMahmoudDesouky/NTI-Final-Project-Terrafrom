# ===================================================================
# 1. TERRAFORM & PROVIDER CONFIG (TOP - REQUIRED)
# ===================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ===================================================================
# 2. MODULES (EXISTING CLUSTER - NO CHANGES NEEDED HERE)
# ===================================================================
module "eks_cluster" {
  source       = "./modules/eks-cluster"
  cluster_name = "ayman-eks"
  region       = "us-east-1"
}

module "eks_nodes" {
  source          = "./modules/eks-node-group"
  cluster_name    = module.eks_cluster.cluster_name
  node_role_arn   = module.eks_cluster.eks_node_role_arn
  subnet_ids      = module.eks_cluster.private_subnets
  min_size        = 2
  max_size        = 4
  desired_size    = 2
  instance_type   = "t3.medium"
  region          = "us-east-1"
}

# ===================================================================
# 3. READ EXISTING CLUSTER OIDC (SAFE - NO MODIFICATIONS)
# ===================================================================

data "aws_caller_identity" "current" {}

# ===================================================================
# 4. IAM ROLE FOR CSI DRIVER (IRSA - SAFE CREATION)
# ===================================================================
# REMOVE the entire data "aws_eks_cluster" "existing" block

# Use module output directly for IRSA role
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${module.eks_cluster.cluster_name}-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks_cluster.cluster_oidc_issuer_url, "https://", "")}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(module.eks_cluster.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(module.eks_cluster.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })

  tags = {
    Name = "${module.eks_cluster.cluster_name}-ebs-csi-driver"
  }
}


resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# ===================================================================
# 5. EKS ADDON INSTALLATION (SAFE - ONLY ADDS ADDON)
# ===================================================================
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks_cluster.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Critical: ONLY depend on IAM resources (avoids triggering cluster updates)
  depends_on = [
    aws_iam_role.ebs_csi_driver,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy
  ]
}

# ===================================================================
# 6. OUTPUTS (NO DUPLICATES)
# ===================================================================
output "cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "cluster_security_group_id" {
  value = module.eks_cluster.cluster_security_group_id
}

output "vpc_id" {
  value = module.eks_cluster.vpc_id
}

output "private_subnets" {
  value = module.eks_cluster.private_subnets
}

output "public_subnet" {
  value = module.eks_cluster.public_subnet
}

output "eks_node_role_arn" {
  value = module.eks_cluster.eks_node_role_arn
}

output "cluster_name" {
  value = module.eks_cluster.cluster_name
}

output "region" {
  value = module.eks_cluster.region
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA (required for addons like EBS CSI)"
  value       = module.eks_cluster.cluster_oidc_issuer_url
}

output "node_group_name" {
  value = module.eks_nodes.node_group_name
}

output "node_instance_type" {
  value = module.eks_nodes.node_instance_type
}

output "desired_node_count" {
  value = module.eks_nodes.desired_node_count
}