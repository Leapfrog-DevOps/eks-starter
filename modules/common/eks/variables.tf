variable "stage" {
  type = string
}

variable "name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}