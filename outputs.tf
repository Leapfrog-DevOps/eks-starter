output "staging_vpc_id" {
  value = module.staging.vpc_id
}

output "staging_private_subnets" {
  value = module.staging.private_subnets
}

output "staging_public_subnets" {
  value = module.staging.public_subnets
}

output "staging_vpc_security_group_id" {
  value = module.staging.vpc_security_group_id
}
