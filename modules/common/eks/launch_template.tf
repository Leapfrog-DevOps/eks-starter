resource "tls_private_key" "eks_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "eks_key_pair" {
  key_name   = "eks-key-pair"
  public_key = tls_private_key.eks_private_key.public_key_openssh

  tags = merge(var.tags, { Name = "${var.name}-eks-key-pair" })
}

resource "aws_secretsmanager_secret" "eks_key_pair" {
  name                    = "${var.name}/${var.stage}/eks_key_pair"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "eks_key_pair_json" {
  secret_id = aws_secretsmanager_secret.eks_key_pair.id
  secret_string = jsonencode({
    "private_key" : tls_private_key.eks_private_key.private_key_pem
    "public_key" : tls_private_key.eks_private_key.public_key_pem
  })
}

resource "aws_launch_template" "eks_node_group_launch_template" {
  name_prefix = "${var.name}-eks-${var.stage}-node"

  monitoring {
    enabled = true
  }

  ebs_optimized = true
  key_name      = aws_key_pair.eks_key_pair.key_name

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted             = true
      kms_key_id            = aws_kms_key.eks_kms_key.arn
      volume_size           = 50
      volume_type           = "gp3"
      iops                  = 3500
      throughput            = 350
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-eks-${var.stage}-node" })
  }
  tag_specifications {
    resource_type = "network-interface"
    tags          = merge(var.tags, { Name = "${var.name}-eks-${var.stage}-node" })
  }
  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.name}-eks-${var.stage}-node" })
  }

  tags = merge(var.tags, { Name = "${var.name}-eks-${var.stage}-node" })
}