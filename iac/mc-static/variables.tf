# bucket name for tf state
variable "tf-bucket" {
  type = string
}

# define the region specific ami images
#variable "ami-images" {
#  type = map(string)
#  default = {
#    "eu-west-2" = "ami-0c00cb2f2d8ea8cc6" # Latest Amazon Linux AMI
#  }
#}

# define the region specific availability zone
variable "aws-zones" {
  type = map(string)

  default = {
    "eu-west-2" = "eu-west-2a"
  }
}

