# examples for running terraform in backend
#terraform {
#  cloud {
#    organization = "may-12"
#
#    workspaces {
#      name = "k8s"
#    }
#  }
#}

## Using a single workspace:
#terraform {
#  backend "remote" {
#    hostname = "app.terraform.io"
#    organization = "may-12"
#
#    workspaces {
#      name = "k8s"
#    }
#  }
#}

# Using multiple workspaces example:
#terraform {
#  backend "remote" {
#    hostname = "app.terraform.io"
#    organization = "company"
#
#    workspaces {
#      prefix = "my-app-"
#    }
#  }
#}
