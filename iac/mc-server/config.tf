terraform {
  backend "s3" {
    bucket         = "terraform-state-catlogic"
    key            = "mincraft-server-running.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 1.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}
