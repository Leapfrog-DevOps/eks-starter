data "aws_caller_identity" "current" {}
# Policy for EKS to use KMS as encryption key
data "aws_iam_policy_document" "eks_node_ebs_encryption" {
  statement {
    sid       = "EnableIAMUserPermissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Required for EKS
  statement {
    sid = "AllowServiceLinkedRoleUseCMK"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_iam_role.AWSServiceRoleForAutoScaling.arn, # required for the ASG to manage encrypted volumes for nodes
        aws_eks_cluster.eks.role_arn,                       # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }
  }

  statement {
    sid       = "AllowAttachmentPersistentResources"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        data.aws_iam_role.AWSServiceRoleForAutoScaling.arn, # required for the ASG to manage encrypted volumes for nodes
        aws_eks_cluster.eks.role_arn,                       # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  depends_on = [aws_eks_cluster.eks]
}


