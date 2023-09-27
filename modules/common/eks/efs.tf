module "efs_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name        = "${var.name}-efs-security-group-${var.stage}"
  description = "Security group for mounting EFS."
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["172.23.0.0/16"]
  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]
  ingress_rules = ["nfs-tcp"]
  egress_rules  = ["all-all"]

  tags = merge(var.tags, { Name = "${var.name}-efs-security-group-${var.stage}" })
}

data "aws_iam_role" "AWSServiceRoleForAutoScaling" {
  #  If this resource doesn't exist then first create Linked Role: AWSServiceRoleForAutoScaling; TF code below
  name = "AWSServiceRoleForAutoScaling"
}

# uncomment this if you need to create AWSServiceRoleForAutoScaling linked role. Uncomment above data
#resource "aws_iam_service_linked_role" "eks_autoscaling_role" {
#  aws_service_name = "autoscaling.amazonaws.com"
#
#  tags = merge(var.tags, { Name = "eks-autoscaling-role" })
#}

resource "aws_iam_policy" "efs_access" {
  name = "${var.name}-efs-client-rw-${var.stage}"
  tags = merge(var.tags, { Name = "${var.name}-efs-client-rw-${var.stage}" })

  policy = <<-EOT
            {
                "Version": "2012-10-17",
                "Statement": [
                     {
                          "Effect": "Allow",
                          "Action": [
                              "elasticfilesystem:ClientMount",
                              "elasticfilesystem:ClientWrite",
                              "elasticfilesystem:DescribeMountTargets",
                              "elasticfilesystem:DescribeAccessPoints",
                              "elasticfilesystem:DescribeFileSystems",
                              "ec2:DescribeAvailabilityZones",
                              "elasticfilesystem:CreateAccessPoint",
                              "elasticfilesystem:DeleteAccessPoint"
                          ],
                          "Resource": "*"
                    }
                ]
            }
            EOT
}
