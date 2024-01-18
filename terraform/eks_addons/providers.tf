provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      "Creator"       = "Oleksandr Bukhanko"
      "Team"          = "Enterprise All Inclusive"
      "Product"       = "Enterprise All Inclusive"
      "Product-Group" = "Enterprise All Inclusive"
      "Environment"   = "qa"
    }
  }
}

terraform {
  backend "s3" {
    bucket  = "backend-bucket-16012024"
    key     = "eks_addons/state"
    region  = "eu-west-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
