terraform {
  backend "s3" {
    profile        = "catlogic_minecraft"
    bucket         = "tf-state-catlogic"
    key            = "mincraft-server.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

provider "aws" {
  profile = var.aws-profile
  region  = var.aws-region
  version = "~> 2.43"
}

provider "null" {
  version = "~> 2.1"
}
