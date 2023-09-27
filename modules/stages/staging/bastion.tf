resource "tls_private_key" "ec2" {
  algorithm = var.tls_private_key_algorithm
  rsa_bits  = var.tls_private_key_rsa_bits
}

resource "aws_key_pair" "default" {
  key_name   = var.name
  public_key = tls_private_key.ec2.public_key_openssh
}

module "ec2_bastion" {
  source                  = "../../common/ec2"
  ec2_instance_name       = "k8s-may-12-bastion"
  ec2_instance_type       = "t3.medium"
  ami_id                  = "ami-04cbc90abb08f0321"
  ec2_security_group_name = join("-", [var.name, 1])
  vpc_id                  = module.vpc.vpc_id
  vpc_cidr                = module.vpc.vpc_cidr
  subnet_id               = module.vpc.public_subnets[0]
  key_name                = aws_key_pair.default.id
  stage                   = var.stage
  tags                    = local.tags
  is_bastion              = true
}

resource "aws_secretsmanager_secret" "ec2_key_pair" {
  name                    = "${var.name}/${var.stage}/bastion_key_pair"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ec2_key_pair_json" {
  secret_id = aws_secretsmanager_secret.ec2_key_pair.id
  secret_string = jsonencode({
    "private_key" : tls_private_key.ec2.private_key_pem
    "public_key" : tls_private_key.ec2.public_key_pem
  })
}
