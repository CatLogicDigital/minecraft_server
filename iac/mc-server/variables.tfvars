aws-region            = "eu-west-2"
ec2-key-pair-name     = "minecraft-key"
tf-bucket = "terraform-state-catlogic"
mc-backup-bucket-name = "catlogic-mc-backup"

aws-zones = {
  "eu-west-2" = "eu-west-2a"
}

ami-images = {
  "eu-west-2" = "ami-0c00cb2f2d8ea8cc6"  # Latest Amazon Linux AMI
}
