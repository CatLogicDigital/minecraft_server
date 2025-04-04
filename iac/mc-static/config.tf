terraform {
  backend "s3" {
    bucket         = "terraform-state-catlogic"
    key            = "mincraft-server.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws-region
}

provider "archive" {
  version = "~> 1.0"
}
