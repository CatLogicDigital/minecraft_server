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
    instance_type = "t4g.medium" #t4g.large if need more memory or lots of mods
 
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
  # IAM Roile for mincraft world backup on S3
  # ------------------------------------
  resource "aws_iam_instance_profile" "minecraft" {
    name = "mc-backup"
    role = "${aws_iam_role.minecraft.name}"
  }
 
  resource "aws_iam_role" "minecraft" {
    name = "mc-backup-role"
    path = "/"
 
    assume_role_policy = <<EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "sts:AssumeRole",
              "Principal": {
                 "Service": "ec2.amazonaws.com"
              },
              "Effect": "Allow",
              "Sid": ""
          }
      ]
  }
  EOF
 
    tags = local.common_tags
  }
 
  resource "aws_iam_role_policy" "minecraft" {
    name = "mc-backup-publish-policy"
    role = "${aws_iam_role.minecraft.id}"
 
    policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "SNS:Publish"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "ec2:TerminateInstances"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
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
 
    // copy pre-configured ec2 instance private key
   provisioner "file" {
     source      = "${path.module}/minecraft-key.pem"
     destination = "id_rsa"
   }
 
    // copy mc auto-shutoff function
    provisioner "file" {
      source      = "../../src/auto-shutoff.py"
      destination = "auto-shutoff.py"
    }
 
    // copy mc deployment and start script
    provisioner "file" {
      source      = "../../src/mc-setup.sh"
      destination = "mc-setup.sh"
    }
    provisioner "file" {
      source      = "../../src/mc-server.sh"
      destination = "mc-server.sh"
    }
    provisioner "file" {
      source      = "../../src/mc-server-launch.sh"
      destination = "mc-server-launch.sh"
    }
 
    // copy tf config and var template
    provisioner "file" {
      source      = "./config.tf"
      destination = "config.tf"
    }
    provisioner "file" {
      source      = "./variables.tf"
      destination = "variables.tf"
    }
    provisioner "file" {
      source      = "../../config/account.tfvars"
      destination = "account.tfvars"
    }

    // install minecraft and sync backup
    provisioner "remote-exec" {
      inline = [
        "chmod a+x mc-*.sh",
        "./mc-setup.sh ${data.aws_s3_bucket.mc_bucket.id} ${data.aws_sns_topic.mc_shutoff.arn} ${var.aws-region}"
      ]
    }

    // start the minecraft server
    provisioner "remote-exec" {
      inline = [
        "./mc-server-launch.sh"
      ]
    }
  }
