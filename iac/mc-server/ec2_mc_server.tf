resource "aws_instance" "minecraft" {
  ami                    = var.ami-images[var.aws-region]
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.minecraft.id
  key_name               = data.aws_key_pair.existing.key_name
  vpc_security_group_ids = [aws_security_group.minecraft.id]
  associate_public_ip_address = true

  tags = {
    Name = "minecraft-server"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y java-17-amazon-corretto",
      "aws s3 cp s3://${var.mc-backup-bucket-name}/minecraft-key.pem ~/minecraft-key.pem",
      "chmod 600 ~/minecraft-key.pem",
      "aws s3 cp s3://${var.mc-backup-bucket-name}/start.sh ~/start.sh",
      "chmod +x ~/start.sh",
      "~/start.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file("${path.module}/minecraft-key.pem")
    }
  }
}

resource "null_resource" "download_pem" {
  provisioner "local-exec" {
    command = "aws s3 cp s3://${var.mc-backup-bucket-name}/minecraft-key.pem ${path.module}/minecraft-key.pem"
  }
}

data "aws_key_pair" "existing" {
  key_name = var.ec2-key-pair-name
}

resource "aws_security_group" "minecraft" {
  name        = "minecraft-sg"
  description = "Allow Minecraft traffic"
  vpc_id      = aws_vpc.minecraft.id

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "minecraft" {
  vpc_id                  = aws_vpc.minecraft.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.aws-zones[var.aws-region]
  map_public_ip_on_launch = true
}

resource "aws_vpc" "minecraft" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "minecraft-vpc"
  }
}
