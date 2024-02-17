provider "aws" {
  region = "us-east-1"
}

variable "vpc_cidr_blocks" {}
variable "subnet_cidr_blocks" {}
variable "avail_zone" {}
variable env_prexi{}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_blocks
  tags = {
    Name: "${var.env_prexi}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_blocks
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prexi}-subnet-1"
  }
}

# output "myapp_subnet_outputs" {
#   value = "test"
# }
# output "myapp_vpc_outputs" {
#   value = "test"
# }