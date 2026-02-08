# modules/eks-node-group/main.tf

provider "aws" {
  region = var.region
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = [var.instance_type]

  scaling_config {
    min_size     = var.min_size
    max_size     = var.max_size
    desired_size = var.desired_size
  }

  capacity_type = "ON_DEMAND"
  disk_size     = 20

  labels = {
    role = "worker"
  }

  tags = {
    Name = "${var.cluster_name}-node-group"
  }

  # Ensure IAM role policies are attached before launching nodes
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy
  ]
}

# Re-declare the required IAM policy attachments (idempotent – safe to re-attach)
# These ensure the role has correct permissions even if this module runs standalone

resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = split("/", var.node_role_arn)[length(split("/", var.node_role_arn)) - 1]
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = split("/", var.node_role_arn)[length(split("/", var.node_role_arn)) - 1]
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = split("/", var.node_role_arn)[length(split("/", var.node_role_arn)) - 1]
}



resource "aws_ebs_volume" "postgres_volume" {
  availability_zone = "us-east-1a"   # لازم نفس AZ بتاعة NodeGroup
  size              = 5              # الحجم بالجيجا
  type              = "gp3"           # أو gp2 لو عايز

  tags = {
    Name = "postgres-ebs-volume"
  }
}


