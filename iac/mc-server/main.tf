locals {
  # prefix for global uniqueness
  prefix = "${var.aws-profile}"

  common_tags = {
    # See https://github.com/hashicorp/terraform/issues/139#issuecomment-250137504
    Name = "minecraft"
  }
}

# reference static SNS queue for auto-shutoff
data "aws_sns_topic" "mc_shutoff" {
  name = "mc-shutoff"
}

# Reference to MC backup bucket for TF config template
data "aws_s3_bucket" "mc_bucket" {
  bucket = var.mc-backup-bucket-name
}

resource "aws_s3_bucket_acl" "mc_backup_acl" {
  bucket = aws_s3_bucket.mc_backup.id
  acl    = "private"
}

# Reference to public IP
data "aws_eip" "mc_ip" {
  tags = {
    Name = "${local.common_tags.Name}"
  }
}
