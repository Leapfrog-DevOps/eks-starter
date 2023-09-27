variable "stage" {
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
  type        = string
  default     = "prod"
}

variable "name" {
  description = "Name  (e.g. `app` or `cluster`)"
  type        = string
}

variable "availability_zones_names" {
  type        = list(string)
  description = "AZs in current Region"
}

variable "tls_private_key_algorithm" {
  type    = string
  default = "RSA"
}

variable "tls_private_key_rsa_bits" {
  type    = number
  default = 4096
}

variable "vpc_cidr_block" {
  type    = string
  default = "172.23.0.0/16"
}

