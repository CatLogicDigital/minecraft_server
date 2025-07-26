aws-region            = "eu-west-2"
ec2-key-pair-name     = "minecraft-key"
tf-bucket = "terraform-state-catlogic"
mc-backup-bucket-name = "catlogic-mc-backup"

aws-zones = {
  "eu-west-2" = "eu-west-2a"
}

ami-images = {
  "eu-west-2" = "ami-0eb260c4d5475b901"  # Amazon Linux 2023 AMI (x86_64)
}
