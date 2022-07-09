## Define AWS provider
provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

## Create a VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "k8s-vpc"
  }
}

## Create a private subnet
resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = "true"
  availability_zone       = var.subnet_availability_zone

  tags = {
    Name = "k8s-private-subnet"
  }
}

## Create a subnet
resource "aws_internet_gateway" "k8s_internet_gateway" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
        Name = "k8s-internet-gateway"
  }
}

resource "aws_route_table" "k8s_route_table" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
        Name = "k8s-route-table"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.k8s_route_table.id
  destination_cidr_block = var.publicDestCIDRblock
  gateway_id             = aws_internet_gateway.k8s_internet_gateway.id
}

resource "aws_route_table_association" "k8s_public_association" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_route_table.id
}

## Create a security group for kubernetes.
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-securit-group"
  vpc_id      = aws_vpc.k8s_vpc.id

  dynamic "ingress" {
    for_each = var.sg_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.sg_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name = "k8s-security-group"
  }
}

## Create masters instances
resource "aws_instance" "k8s-master" {
  count                       = var.master_count
  ami                         = var.ami
  instance_type               = var.image_flavor.master
  key_name                    = var.aws_key_pair_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  subnet_id                   = aws_subnet.k8s_subnet.id
  associate_public_ip_address = true

  tags = {
    Name = "${var.tag_name}-master-${count.index}"
  }
}

## Create nodes instances
resource "aws_instance" "k8s-node" {
  count                       = var.node_count
  ami                         = var.ami
  instance_type               = var.image_flavor.worker
  key_name                    = var.aws_key_pair_name
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  subnet_id                   = aws_subnet.k8s_subnet.id
  associate_public_ip_address = true

  tags = {
    Name = "${var.tag_name}-node-${count.index}"
  }
}
