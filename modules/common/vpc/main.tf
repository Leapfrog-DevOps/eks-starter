resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge({
    Name = "${var.name}-${var.stage}-vpc"
  }, var.tags)
}

# Create a Private Subnet
resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  vpc_id            = aws_vpc.main.id
  availability_zone = var.availability_zones[count.index]
  tags = merge({
    Name = "${var.name}-private-subnet-${var.stage}-${count.index}",
    Type = "private"
  }, var.tags)
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge({
    Name = "${var.name}-public-subnet-${var.stage}-${count.index}",
    Type = "public"
  }, var.tags)
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge({ Name = "${var.name}-igw-${var.stage}" }, var.tags)
}

# Route the Public Subnet through IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Create a NAT gateway with an EIP for each private subnet to get internet connectivity
resource "aws_eip" "gw" {
  count = 1
  vpc   = true
  depends_on = [
    aws_internet_gateway.igw
  ]
  tags = merge({ Name = "${var.name}-eip-${var.stage}" }, var.tags)

}

resource "aws_nat_gateway" "gw" {
  count         = 1
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)
  tags          = merge({ Name = "${var.name}-natgw-${var.stage}" }, var.tags)
  depends_on    = [aws_eip.gw]
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw[0].id
  }
  tags       = merge({ Name = "${var.name}-private-rtb-${var.stage}" }, var.tags)
  depends_on = [aws_nat_gateway.gw]
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
  depends_on     = [aws_route_table.private]
}

resource "aws_security_group" "default" {
  name        = join("-", [var.name, "vpc", "security-group"])
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "VPC Access"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({ Name = "${var.name}-sg-${var.stage}" }, var.tags)
}
