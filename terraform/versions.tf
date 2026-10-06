terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  #added to every resource to tell in the console what Terraform made
  default_tags {
    tags = {
      Project   = "gbfs-collector"
      ManagedBy = "terraform"
    }
  }
}
