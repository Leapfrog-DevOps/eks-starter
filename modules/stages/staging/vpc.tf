module "vpc" {
  source             = "../../common/vpc"
  name               = var.name
  cidr_block         = var.vpc_cidr_block
  stage              = var.stage
  availability_zones = var.availability_zones_names
  tags               = local.tags
}
