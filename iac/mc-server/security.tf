resource "aws_security_group" "minecraft" {
  vpc_id      = aws_vpc.minecraft.id
  description = "Allow Minecraft and SSH from my IP"
  tags        = local.common_tags

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["195.144.8.62/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["195.144.8.62/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
