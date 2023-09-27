variable "ec2_security_group_name" {
  type = string
}

variable "ec2_security_group_description" {
  type    = string
  default = "EC2 Security Group Managed By Terraform"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "ec2_instance_type" {
  type    = string
  default = "t2.small"
}

variable "subnet_id" {
  type = string
}


variable "ec2_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "image_filter_values" {
  type    = list(string)
  default = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
}

variable "virtualization_filter_values" {
  type    = list(string)
  default = ["hvm"]
}

variable "image_owners" {
  type    = list(string)
  default = ["099720109477"]
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "ec2_instance_name" {
  type = string
}

variable "ec2_volume_size" {
  type    = string
  default = 30
}

variable "ami_id" {
  type    = string
  default = "ami-068257025f72f470d"
}

variable "key_name" {
  type = string
}

variable "is_bastion" {
  type    = bool
  default = false
}

variable "userdata" {
  type    = string
  default = ""
}

variable "ebs_optimized" {
  type    = bool
  default = false
}

variable "assign_elastic_ip" {
  type    = bool
  default = false
}

variable "stage" {
  type = string
}
