terraform {
  backend "s3" {
    bucket         = "terraform-state-catlogic"
    key            = "mincraft-server.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 1.0"
    }
  }
}
