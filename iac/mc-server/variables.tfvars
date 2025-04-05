aws-region            = "eu-west-2"
ec2-key-pair-name     = "minecraft-key"
tf-bucket = "terraform-state-catlogic"
mc-backup-bucket-name = "catlogic-mc-backup"

aws-zones = {
  "eu-west-2" = "eu-west-2a"
}

ami-images = {
  "eu-west-2" = "ami-0faea58d4f6a5b206"  # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type - no UEFI
}
