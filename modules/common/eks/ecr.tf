resource "aws_ecr_repository" "node_chat" {
  name = "${var.name}/${var.stage}/node_chat"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.eks_kms_key.arn
  }

  tags = merge(var.tags, { Name = "${var.name}-${var.stage}-node_chat" })
}

resource "aws_ecr_lifecycle_policy" "node_chat_expire_untagged" {
  repository = aws_ecr_repository.node_chat.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images.",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ecr_repo_access" {
  name = "${var.name}-${var.stage}-repo-access"
  tags = merge(var.tags, { Name = "${var.name}-${var.stage}-repo-access" })

  policy = <<-EOT
          {
              "Version": "2012-10-17",
              "Statement": [
                  {
                      "Sid": "KMSKeyAccess",
                      "Action": [
                          "kms:Encrypt",
                          "kms:Decrypt",
                          "kms:ReEncrypt*",
                          "kms:GenerateDataKey*"
                      ],
                      "Effect": "Allow",
                      "Resource": [
                          "${aws_kms_key.eks_kms_key.arn}"
                      ]
                  },
                  {
                      "Sid": "ECRRepoReadOnly",
                      "Effect": "Allow",
                      "Action": [
                          "ecr:GetAuthorizationToken",
                          "ecr:BatchCheckLayerAvailability",
                          "ecr:GetDownloadUrlForLayer",
                          "ecr:GetRepositoryPolicy",
                          "ecr:DescribeRepositories",
                          "ecr:ListImages",
                          "ecr:DescribeImages",
                          "ecr:BatchGetImage",
                          "ecr:DescribeImageScanFindings"
                      ],
                      "Resource": [
                          "${aws_ecr_repository.node_chat.arn}"
                      ]
                  }
              ]
          }
            EOT
}

resource "aws_iam_role_policy_attachment" "ecr_repo_access" {
  policy_arn = aws_iam_policy.ecr_repo_access.arn
  role       = aws_iam_role.eks_cluster_role.name
}
