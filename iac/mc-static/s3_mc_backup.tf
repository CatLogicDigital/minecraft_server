provider "aws" {
  region = var.aws-region
}

resource "aws_s3_bucket" "mc_backup" {
  bucket = "${local.prefix}-mc-backup" 
  tags = "${local.common_tags}"
}

resource "aws_s3_bucket_acl" "mc_backup_acl" {
  bucket = aws_s3_bucket.mc_backup.id
  acl    = "private"
}
