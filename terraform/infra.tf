#Declares var "vpc_id" to equal default
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-d91a04bd"
}

#Sets provider to "aws" and region to "us-west-2"
provider "aws" {
  region = "us-west-2"
}

#Creates a VPC Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "default_ig"
  }
}

#Creates a public subnet with CIDR of "172.31.12.0/24" in us-west-2a
resource "aws_subnet" "public_subnet_a" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.12.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.gw"]

  tags {
     Name = "public_a"
    }
}

#Creates a public subnet with CIDR of "172.31.13.0/24" in us-west-2b
resource "aws_subnet" "public_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.13.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.gw"]

  tags {
     Name = "public_b"
  }
}

#Creates a public subnet with CIDR of "172.31.14.0/24" in us-west-2c
resource "aws_subnet" "public_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.14.0/24"
  availability_zone = "us-west-2c"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.gw"]

  tags {
    Name = "public_c"
  }
}

#Creates a public route table in aws with the Internet Gateway
resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}

#Assosciates public_subnet_a to aws_route_table.public_routing_table
resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

#Assosciates public_subnet_b to aws_route_table.public_routing_table
resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_b.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

#Assosciates public_subnet_c to aws_route_table.public_routing_table
resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.public_subnet_c.id}"
  route_table_id = "${aws_route_table.public_routing_table.id}"
}

#Creates a private subnet with CIDR of "172.31.0.0/22" in us-west-2a
resource "aws_subnet" "private_subnet_a" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.0.0/22"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = false
  tags {
    Name = "private_a"
  }
}

#Creates a private subnet with CIDR of "172.31.4.0/22" in us-west-2b
resource "aws_subnet" "private_subnet_b" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.4.0/22"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = false
  
  tags {
    Name = "private_b"
  }
}

#Creates a private subnet with CIDR of "172.31.8.0/22" in us-west-2c
resource "aws_subnet" "private_subnet_c" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "172.31.8.0/22"
  availability_zone = "us-west-2c"
  map_public_ip_on_launch = false

  tags {
    Name = "private_c"
  }
}

#Creates an Elastic IP to be attached to the NAT Gateway
resource "aws_eip" "nat" { 
  vpc = true
}

#Creates a NAT gateway with subnet_id of "aws_subnet.public_subnet_a"
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  depends_on = ["aws_internet_gateway.gw"]
}

#Creates a private routing table in aws with the NAT Gateway
resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
  cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }

  tags {
    Name = "private_routing_table"
  }
}

#Assosciates private_subnet_a to aws_route_table.private_routing_table
resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_a.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

#Assosciates private_subnet_b to aws_route_table.private_routing_table
resource "aws_route_table_association" "private_subnet_b_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_b.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

#Assosciates private_subnet_c to aws_route_table.private_routing_table
resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
  subnet_id = "${aws_subnet.private_subnet_c.id}"
  route_table_id = "${aws_route_table.private_routing_table.id}"
}

#Allows access from SSH to current IP address
resource "aws_security_group" "ssh" {
  vpc_id = "${var.vpc_id}"
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0 
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Creates an Elastic IP to be attached to the NAT Gateway
resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc = true
}

#Creates a single bastion EC2 instance in public_subnet_a
resource "aws_instance" "bastion" {
  ami = "ami-b04e92d0"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  security_groups = ["${aws_security_group.ssh.id}"]
}
