provider "aws" {
  region = "us-east-1"
}

# fisrt ec2
resource "aws_instance" "sever-1" {
  ami           = "ami-0b93ce03dcbcb10f6"
  instance_type = "t3.micro"
  key_name = "Kub"
  
  tags = {
    Name = "Server_1"
  }
  network_interface {
    network_interface_id = aws_network_interface.ans-ni.id
    device_index         = 0
  }
}

#second ec2
resource "aws_instance" "server-2" {
  ami           = "ami-0b93ce03dcbcb10f6"
  instance_type = "t3.micro"
  key_name = "Kub"

  tags = {
    Name = "Server_2"
  }
  network_interface {
    network_interface_id = aws_network_interface.ans1-ni.id
    device_index         = 0
  }
}

# 1.create vpc
resource "aws_vpc" "ans-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "ansible_vpc"
  }
}

# 2.create internet gateway
resource "aws_internet_gateway" "ans-igw" {
  vpc_id = aws_vpc.ans-vpc.id

  tags = {
    Name = "ansible-igw"
  }
}

# 3.create custom route table
resource "aws_route_table" "ans-rt" {
  vpc_id = aws_vpc.ans-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ans-igw.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_internet_gateway.ans-igw.id
  # }

  tags = {
    Name = "Dev-crt"
  }
}

# 4.create a subnet
resource "aws_subnet" "ans-subnet" {
  vpc_id     = aws_vpc.ans-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Dev-subnet"
  }
}

# 5.associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.ans-subnet.id
  route_table_id = aws_route_table.ans-rt.id
}
# resource "aws_route_table_association" "b" {
#   gateway_id     = aws_internet_gateway.ans-igw.id
#   route_table_id = aws_route_table.ans-rt.id
# }

# 6.create security group to allow port 22,80,443
resource "aws_security_group" "web" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.ans-vpc.id

  ingress {
    description      = "ssh from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "https from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Dev-web"
  }
}

# 7.create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "ans-ni" {
  subnet_id       = aws_subnet.ans-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.web.id]
}

resource "aws_network_interface" "ans1-ni" {
  subnet_id       = aws_subnet.ans-subnet.id
  private_ips     = ["10.0.1.53"]
  security_groups = [aws_security_group.web.id]
}


# 8.assign an elastic ip to the network interface created in step 7
resource "aws_eip" "ni-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.ans-ni.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.ans-igw
  ]
}


resource "aws_eip" "ni1-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.ans1-ni.id
  associate_with_private_ip = "10.0.1.53"
  depends_on = [
    aws_internet_gateway.ans-igw
  ]
}
