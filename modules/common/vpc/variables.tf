variable "az_count" {
  type    = string
  default = "2"
}

variable "cidr_block" {
  type    = string
  default = "172.11.0.0/16"
}

variable "namespace" {
  description = "Namespace (e.g. `appealio` or `aplo`)"
  type        = string
  default     = ""
}

variable "stage" {
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
  type        = string
  default     = ""
}


variable "name" {
  description = "Name  (e.g. `app` or `cluster`)"
  type        = string
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name` and `attributes`"
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs in current Region"
}
