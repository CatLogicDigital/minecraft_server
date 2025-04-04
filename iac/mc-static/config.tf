terraform {
  backend "s3" {
    profile        = "catlogic_minecraft"
    bucket         = "terraform-state-catlogic"
    key            = "mincraft-server.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

provider "aws" {
  profile = var.aws-profile
  region  = var.aws-region
}

provider "archive" {
  version = "~> 1.0"
}
