aws-region            = "eu-west-2"
ec2-key-pair-name     = "minecraft-key"
tf-bucket = "terraform-state-catlogic"
mc-backup-bucket-name = "catlogic-mc-backup"

aws-zones = {
  "eu-west-2" = "eu-west-2a"
}

ami-images = {
  "eu-west-2" = "ami-0532f1280ac457a8f"  # Amazon Linux 2023 6,1 AMI (ami-0175d4f2509d1d9e8 for x64)
}
