# ------------------------------------
# Minecraft EC2 server
# ------------------------------------

# import existing ec2 keypair
data "aws_key_pair" "existing" {
  key_name = var.ec2-key-pair-name
}

# import s3 used for backup
data "aws_s3_bucket" "mc_backup" {
  bucket = var.mc-backup-bucket-name
}

resource "aws_instance" "minecraft" {
  instance_type = "t2.medium"

  ami               = var.ami-images[var.aws-region]
  security_groups   = [aws_security_group.minecraft.id]
  availability_zone = var.aws-zones[var.aws-region]
  key_name          = data.aws_key_pair.existing.key_name
  depends_on        = [aws_internet_gateway.minecraft]
  subnet_id         = aws_subnet.minecraft.id

  iam_instance_profile = aws_iam_instance_profile.minecraft.name

  root_block_device {
    volume_type = "standard"
    volume_size = 40
  }

  tags        = local.common_tags
  volume_tags = local.common_tags
}

resource "aws_eip_association" "minecraft" {
  instance_id   = aws_instance.minecraft.id
  allocation_id = data.aws_eip.mc_ip.id
}

# ------------------------------------
# IAM Role and Policy for EC2 Termination
# ------------------------------------
resource "aws_iam_role" "ec2_termination_role" {
  name = "ec2-termination-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_termination_policy" {
  name = "ec2-termination-policy"
  role = aws_iam_role.ec2_termination_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:TerminateInstances",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/Name": "minecraft-server"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_termination_instance_profile" {
  name = "ec2-termination-instance-profile"
  role = aws_iam_role.ec2_termination_role.name
}

# Attach termination role to the EC2 instance
resource "aws_instance" "minecraft" {
  # Existing configurations...
  iam_instance_profile = aws_iam_instance_profile.ec2_termination_instance_profile.name
}

# -----------------------------------------
# Provision the minecraft server using remote-exec
# -----------------------------------------
resource "null_resource" "minecraft" {
  triggers = {
    public_ip = aws_eip_association.minecraft.public_ip
  }

  connection {
    type        = "ssh"
    host        = aws_eip_association.minecraft.public_ip
    user        = "ec2-user"
    port        = "22"
    private_key = file("${path.module}/minecraft-key.pem")
  }

  # copy mc deployment and start script
  provisioner "file" {
    source      = "../../src/mc-server.sh"
    destination = "mc-server.sh"
  }

  # provision the script to handle termination
  provisioner "remote-exec" {
    inline = [
      "chmod +x mc-server.sh",
      "./mc-server.sh terminate"
    ]
  }
}
