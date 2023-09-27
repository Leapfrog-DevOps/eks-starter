resource "aws_eks_node_group" "eks_node_private" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.name}-eks-${var.stage}-node"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids

  version  = aws_eks_cluster.eks.version
  ami_type = "AL2_x86_64"

  capacity_type = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.eks_node_group_launch_template.id
    version = aws_launch_template.eks_node_group_launch_template.latest_version
  }

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 10
  }

  update_config {
    max_unavailable = 2
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(var.tags, { Name = "${var.name}-eks-${var.stage}-node-group", Environment = "staging" })
}

resource "aws_eks_node_group" "eks_node_private1" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.name}-eks-${var.stage}-node-1"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids

  version  = aws_eks_cluster.eks.version
  ami_type = "AL2_x86_64"

  capacity_type = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.eks_node_group_launch_template.id
    version = aws_launch_template.eks_node_group_launch_template.latest_version
  }

  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 10
  }

  update_config {
    max_unavailable = 2
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(var.tags, { Name = "${var.name}-eks-${var.stage}-node-group-1", Environment = "staging" })
}
