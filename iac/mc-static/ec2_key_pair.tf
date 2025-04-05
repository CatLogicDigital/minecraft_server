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

# Upload private key to S3 backup bucket
resource "null_resource" "upload_pem_to_s3" {
  depends_on = [null_resource.fix_private_key_permissions]

  provisioner "local-exec" {
    command = "aws s3 cp ${path.module}/minecraft-key.pem s3://${var.mc-backup-bucket-name}/minecraft-key.pem"
  }
}
