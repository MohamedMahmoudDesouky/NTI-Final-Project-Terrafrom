# modules/eks-cluster/outputs.tf

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
}

output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "public_subnet" {
  value = aws_subnet.public.id
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "kubeconfig_cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "region" {
  value = var.region
}

# ===== ADD THIS MISSING OUTPUT =====
output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA (required for addons like EBS CSI)"
  value       = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}