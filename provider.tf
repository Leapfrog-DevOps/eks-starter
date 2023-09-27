terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.66.1"
    }
  }
}

# default provider to N. Virginia i.e. us-east-1
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "mumbai"
  region = "ap-south-1"
}

provider "aws" {
  alias  = "ohio"
  region = "us-east-2"
}

provider "aws" {
  alias  = "california"
  region = "us-west-1"
}

provider "aws" {
  alias  = "oregon"
  region = "us-west-2"
}

