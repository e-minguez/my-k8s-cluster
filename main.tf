provider "aws" {
  profile = "default"
  region  = "eu-south-2"
}

data "aws_ami" "debian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }

  owners = ["136693071363"] 
}


resource "aws_vpc" "edu_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Edu Custom VPC"
  }
}

resource "aws_subnet" "edu_public_subnet" {
  vpc_id            = aws_vpc.edu_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-south-2b"

  tags = {
    Name = "Edu Public Subnet"
  }
}

resource "aws_subnet" "edu_private_subnet" {
  vpc_id            = aws_vpc.edu_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-south-2b"

  tags = {
    Name = "Edu Private Subnet"
  }
}

resource "aws_internet_gateway" "edu_ig" {
  vpc_id = aws_vpc.edu_vpc.id

  tags = {
    Name = "Edu Internet Gateway"
  }
}

resource "aws_route_table" "edu_public_rt" {
  vpc_id = aws_vpc.edu_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.edu_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.edu_ig.id
  }

  tags = {
    Name = "Edu Public Route Table"
  }
}

resource "aws_route_table_association" "edu_public_1_rt_a" {
  subnet_id      = aws_subnet.edu_public_subnet.id
  route_table_id = aws_route_table.edu_public_rt.id
}

resource "aws_security_group" "edu_web_ssh_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.edu_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "edu" {
  ami           = data.aws_ami.debian.id
  instance_type = "m5.2xlarge"
  key_name      = "edu-keypair"

  subnet_id                   = aws_subnet.edu_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.edu_web_ssh_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash -ex

  apt update
  apt upgrade -y
  EOF

  tags = {
    "Name" : "Edu"
  }
}
