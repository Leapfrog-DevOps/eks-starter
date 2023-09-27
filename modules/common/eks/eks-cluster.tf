module "eks_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name        = "${var.name}-eks-cluster-sg-${var.stage}"
  description = "Security group for EKS Cluster."
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]
  ingress_rules = ["https-443-tcp"]
  egress_rules  = ["all-all"]

  tags = var.tags
}

resource "aws_eks_cluster" "eks" {
  name     = "${var.name}-eks-${var.stage}"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.25"
  tags     = merge(var.tags, { Name = "${var.name}-eks-${var.stage}" })

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [module.eks_security_group.security_group_id]
  }

  kubernetes_network_config {
    service_ipv4_cidr = "10.23.0.0/16"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]

  lifecycle {
    ignore_changes = [tags]
  }
}

