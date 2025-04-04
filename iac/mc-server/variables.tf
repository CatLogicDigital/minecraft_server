# region
variable "aws-region" {
  type = string
}

# key-name 
variable "ec2-key-pair-name" {
  type = string
}

# bucket name for tf state
variable "tf-bucket" {
  type = string
}

# bucket for backup
variable "mc-backup-bucket-name" {
  type        = string
  description = "The name of the backup S3 bucket"
}

# define the region specific ami images
variable "ami-images" {
  type = map(string)

  default = {
    "eu-central-1" = "ami-0233214e13e500f77"
  }
}

# define the region specific availability zone
variable "aws-zones" {
  type = map(string)

  default = {
    "eu-central-1" = "eu-central-1a"
  }
}

