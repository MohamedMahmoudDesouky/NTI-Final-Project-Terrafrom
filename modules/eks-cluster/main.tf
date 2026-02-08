# modules/eks-cluster/main.tf

provider "aws" {
  region = var.region
}

# --- VPC ---
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                           = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Get AZs dynamically
data "aws_availability_zones" "available" {
  state = "available"
}

# --- Public Subnet (for NAT Gateway) ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                    = "${var.cluster_name}-public-subnet"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                = "1"
  }
}

# --- Private Subnets (for EKS nodes) ---
resource "aws_subnet" "private" {
  count             = length(var.eks_private_subnet_cidrs)
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.eks_private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index + 1] # avoid AZ0 if used above

  tags = {
    Name                                    = "${var.cluster_name}-private-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"       = "1"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# --- Elastic IP for NAT Gateway ---
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.cluster_name}-nat-eip"
  }
}

# --- NAT Gateway (in public subnet) ---
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.cluster_name}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# --- Route Tables ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

# --- Route Table Associations ---
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- Security Group for EKS Control Plane ---
resource "aws_security_group" "eks_cluster_sg" {
  vpc_id = aws_vpc.eks_vpc.id

  description = "EKS cluster security group"

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  version  = "1.30" # Use latest stable; adjust as needed
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    # endpoint_private_access = true
    # endpoint_public_access  = true
    # public_access_cidrs     = ["0.0.0.0/0"] # Optional: restrict later if needed
  }

  # Restrict Kubernetes API server access to private subnets only
  # (Note: AWS doesn't allow limiting API access *by subnet*, but you can limit by CIDR.
  # Since private subnets are internal, we rely on network design + security groups.)
  # For tighter control, consider using a Bastion or VPC endpoints.

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy
  ]

  tags = {
    Name = var.cluster_name
  }
}


