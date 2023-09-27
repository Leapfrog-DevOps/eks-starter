module "eks" {
  source = "../../common/eks"

  stage              = var.stage
  name               = var.name
  tags               = local.tags
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
}