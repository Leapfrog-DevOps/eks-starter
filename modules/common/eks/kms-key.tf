resource "aws_kms_key" "eks_kms_key" {
  description             = "Customer Managed KMS for EKS"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.eks_node_ebs_encryption.json
  tags                    = merge(var.tags, { Name = "${var.name}-EKS Key" })
}

resource "aws_kms_alias" "kms_eks_ebs" {
  target_key_id = aws_kms_key.eks_kms_key.id
  name          = "alias/${var.name}-eks/ebs"
}