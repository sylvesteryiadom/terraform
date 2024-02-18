provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_blocks
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_blocks
  availability_zone = var.avail_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}

# route tables

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name : "${var.env_prefix}-igw"
  }
}

# resource "aws_route_table" "myapp-route-table" {
#   vpc_id = aws_vpc.myapp-vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }
#   tags = {
#     Name: "${var.env_prefix}-rtb"
#   }
# }

# resource "aws_route_table_association" "myapp-rtb-association" {
#   subnet_id = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp-route-table.id
# }

resource "aws_default_route_table" "main-default-rt" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name : "${var.env_prefix}-main-rtb"
  }
}

# firewall rules for ec2 instance
# resource "aws_security_group" "myapp-sg" {
#   name        = "myapp-sg"
#   description = "Security group for EC2 instance allowing SSH access"

#   vpc_id = aws_vpc.myapp-vpc.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [var.my_ip] # Restrict to specific IPs if possible
#   }

#   ingress {
#     from_port  = 8080
#     to_port    = 8080
#     protocol   = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Optionally, you can add egress rules here
#     egress {
#     from_port  = 0
#     to_port    = 0
#     protocol   = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

# tags = {
#     Name : "${var.env_prefix}-sg"
#   }
# }

resource "aws_default_security_group" "default-sg" {
  # name        = "default-sg"
  # description = "Security group for EC2 instance allowing SSH access"

  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Restrict to specific IPs if possible
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optionally, you can add egress rules here
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name : "${var.env_prefix}-default-sg"
  }
}

# get ami id dynamically

data "aws_ami" "latest-amazon-ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Adding ec2 instance

# generate keypair
resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.my_public_key)
  # public_key = var.my_public_key
}
resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.latest-amazon-ami.id
  instance_type = var.instance_type

  # optional args

  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone      = var.avail_zone
  # create public IP address
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name

  # installing apps
  user_data = <<EOF
                #!/bin/bash
                sudo yum update -y && sudo yum install docker -y
                sudo systemctl start docker
                sudo usermod -aG docker ec2-user
                docker run -p nginx 8080:80
              EOF
              
  tags = {
    "Name" : "${var.env_prefix}-server"
  }
}


output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-ami.id
}

output "myapp_server_public_ip" {
  value = aws_instance.myapp-server.public_ip
}