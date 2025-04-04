terraform {
  backend "s3" {
    profile        = "catlogic_minecraft"
    bucket         = "tf-state-catelogic"
    key            = "mincraft-server.tfstate"
    region         = "eu-north-1"
    encrypt        = true
  }
}

provider "aws" {
  profile = var.aws-profile
  region  = var.aws-region
  version = "~> 2.43"
}

provider "archive" {
  version = "~> 1.0"
}
