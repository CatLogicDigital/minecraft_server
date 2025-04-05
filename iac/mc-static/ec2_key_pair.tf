# Generate a new private key
resource "tls_private_key" "mc_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a new key pair using the generated public key
resource "aws_key_pair" "mc_key_pair" {
  key_name   = "minecraft-key"
  public_key = tls_private_key.mc_key.public_key_openssh
}

# Output the private key to a file
resource "local_file" "mc_private_key" {
  content  = tls_private_key.mc_key.private_key_pem
  filename = "${path.module}/minecraft-key.pem"
}

# Ensure the private key file has appropriate permissions
resource "null_resource" "fix_private_key_permissions" {
  depends_on = [local_file.mc_private_key]

  provisioner "local-exec" {
    command = "chmod 600 ${path.module}/minecraft-key.pem"
  }
}
