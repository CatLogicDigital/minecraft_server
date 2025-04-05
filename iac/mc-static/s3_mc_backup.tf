provider "aws" {
  region = var.aws-region
}

resource "aws_s3_bucket" "mc_backup" {
  bucket = "${local.prefix}-mc-backup" 
  tags = "${local.common_tags}"
}
