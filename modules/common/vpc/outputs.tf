output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output "vpc_security_group_id" {
  value = aws_security_group.default.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}
