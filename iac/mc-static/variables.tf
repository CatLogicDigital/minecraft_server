# bucket name for tf state
variable "tf-bucket" {
  type = string
}

# define the region specific ami images
variable "ami-images" {
  type = map(string)

  default = {
    "eu-west-2" = "ami-0233214e13e500f77"
  }
}

# define the region specific availability zone
variable "aws-zones" {
  type = map(string)

  default = {
    "eu-west-2" = "eu-west-2a"
  }
}

