# ------------------------------------
# Add IAM Role and Policy for EC2 Termination
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

# ------------------------------------
# Update EC2 Instance (Attach IAM Role)
# ------------------------------------
resource "aws_instance" "minecraft" {
  # Existing configurations...

  # Attach the new IAM instance profile for termination
  iam_instance_profile = aws_iam_instance_profile.ec2_termination_instance_profile.name

  # Other existing configurations remain unchanged
}
