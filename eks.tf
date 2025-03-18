# Provider configuration
provider "aws" {
  region = "us-east-1"
}

# VPC for the EKS cluster
resource "aws_vpc" "custom_eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "custom-eks-vpc"
  }
}

# Public Subnets (at least 2 for high availability)
resource "aws_subnet" "custom_eks_public_subnet_1" {
  vpc_id                  = aws_vpc.custom_eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name                          = "custom-eks-public-subnet-1"
    "kubernetes.io/role/elb"      = "1"
    "kubernetes.io/cluster/custom-eks" = "shared"
  }
}

resource "aws_subnet" "custom_eks_public_subnet_2" {
  vpc_id                  = aws_vpc.custom_eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name                          = "custom-eks-public-subnet-2"
    "kubernetes.io/role/elb"      = "1"
    "kubernetes.io/cluster/custom-eks" = "shared"
  }
}

# Private Subnets (for worker nodes)
resource "aws_subnet" "custom_eks_private_subnet_1" {
  vpc_id            = aws_vpc.custom_eks_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name                              = "custom-eks-private-subnet-1"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/custom-eks" = "shared"
  }
}

resource "aws_subnet" "custom_eks_private_subnet_2" {
  vpc_id            = aws_vpc.custom_eks_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name                              = "custom-eks-private-subnet-2"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/custom-eks" = "shared"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "custom_eks_igw" {
  vpc_id = aws_vpc.custom_eks_vpc.id
  tags = {
    Name = "custom-eks-igw"
  }
}

# Route Table for public subnets
resource "aws_route_table" "custom_eks_public_rt" {
  vpc_id = aws_vpc.custom_eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_eks_igw.id
  }
  tags = {
    Name = "custom-eks-public-rt"
  }
}

resource "aws_route_table_association" "custom_eks_public_rt_assoc_1" {
  subnet_id      = aws_subnet.custom_eks_public_subnet_1.id
  route_table_id = aws_route_table.custom_eks_public_rt.id
}

resource "aws_route_table_association" "custom_eks_public_rt_assoc_2" {
  subnet_id      = aws_subnet.custom_eks_public_subnet_2.id
  route_table_id = aws_route_table.custom_eks_public_rt.id
}

# NAT Gateway for private subnets
resource "aws_eip" "custom_eks_nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "custom_eks_nat" {
  allocation_id = aws_eip.custom_eks_nat_eip.id
  subnet_id     = aws_subnet.custom_eks_public_subnet_1.id
  tags = {
    Name = "custom-eks-nat"
  }
}

# Route Table for private subnets
resource "aws_route_table" "custom_eks_private_rt" {
  vpc_id = aws_vpc.custom_eks_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.custom_eks_nat.id
  }
  tags = {
    Name = "custom-eks-private-rt"
  }
}

resource "aws_route_table_association" "custom_eks_private_rt_assoc_1" {
  subnet_id      = aws_subnet.custom_eks_private_subnet_1.id
  route_table_id = aws_route_table.custom_eks_private_rt.id
}

resource "aws_route_table_association" "custom_eks_private_rt_assoc_2" {
  subnet_id      = aws_subnet.custom_eks_private_subnet_2.id
  route_table_id = aws_route_table.custom_eks_private_rt.id
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "custom_eks_role" {
  name = "custom-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_eks_policy" {
  role       = aws_iam_role.custom_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "custom_eks_node_role" {
  name = "custom-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_eks_node_policy" {
  role       = aws_iam_role.custom_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "custom_eks_cni_policy" {
  role       = aws_iam_role.custom_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "custom_eks_registry_policy" {
  role       = aws_iam_role.custom_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster
resource "aws_eks_cluster" "custom_eks" {
  name     = "custom-eks"
  role_arn = aws_iam_role.custom_eks_role.arn
  version  = "1.29" # Adjust to your desired Kubernetes version

  vpc_config {
    subnet_ids = [
      aws_subnet.custom_eks_public_subnet_1.id,
      aws_subnet.custom_eks_public_subnet_2.id,
      aws_subnet.custom_eks_private_subnet_1.id,
      aws_subnet.custom_eks_private_subnet_2.id
    ]
    endpoint_public_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.custom_eks_policy
  ]
}

# EKS Node Group (Simplified, no SSH)
resource "aws_eks_node_group" "custom_eks_node_group" {
  cluster_name    = aws_eks_cluster.custom_eks.name
  node_group_name = "custom-eks-nodes"
  node_role_arn   = aws_iam_role.custom_eks_node_role.arn
  subnet_ids      = [
    aws_subnet.custom_eks_private_subnet_1.id,
    aws_subnet.custom_eks_private_subnet_2.id
  ]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  instance_types = ["t3.medium"] # Default instance type

  depends_on = [
    aws_iam_role_policy_attachment.custom_eks_node_policy,
    aws_iam_role_policy_attachment.custom_eks_cni_policy,
    aws_iam_role_policy_attachment.custom_eks_registry_policy
  ]
}

# Output cluster details
output "cluster_endpoint" {
  value = aws_eks_cluster.custom_eks.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.custom_eks.certificate_authority[0].data
}

output "cluster_name" {
  value = aws_eks_cluster.custom_eks.name
}

output "kubeconfig_update_command" {
  value       = "aws eks --region us-east-1 update-kubeconfig --name custom-eks"
  description = "Command to update kubectl configuration for the custom-eks cluster"
}