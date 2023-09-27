module "staging" {
  source                   = "./modules/stages/staging"
  name                     = "k8s-may-12"
  stage                    = "staging"
  availability_zones_names = data.aws_availability_zones.available.names
}
