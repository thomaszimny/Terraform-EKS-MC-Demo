
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.6.0"
    }
  }
}

provider "aws" {

  # Configuration options
  region = "us-east-1"

  # Authentication
    # Use AWS configure to store credential information at "~/.aws/credentials"
    # Reference Link (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
  shared_credentials_files = [ "~/.aws/credentials" ]
    
}

resource "aws_vpc" "MC-EKS-VPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MC-EKS-VPC"
  }
}

resource "aws_internet_gateway" "MC-Gateway" {
  vpc_id = aws_vpc.MC-EKS-VPC.id

  tags = {
    Name = "MC-Internet-Gateway"
  }
}

resource "aws_route_table" "MC-Route-Table" {
  vpc_id = aws_vpc.MC-EKS-VPC.id

  tags = {
    Name = "example"
  }
}

resource "aws_route" "MC-Route" {
  route_table_id = aws_route_table.MC-Route-Table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.MC-Gateway.id
  depends_on = [aws_route_table.MC-Route-Table]
}

resource "aws_route" "MC-Route-ipv6" {
  route_table_id         = aws_route_table.MC-Route-Table.id
  destination_ipv6_cidr_block        = "::/0"
  gateway_id = aws_internet_gateway.MC-Gateway.id
  depends_on = [aws_route_table.MC-Route-Table]
}

resource "aws_subnet" "MC-Subnet-1" {
  vpc_id     = aws_vpc.MC-EKS-VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "MC-Subnet-1"
  }
}

resource "aws_route_table_association" "MC-Route-Table-Association" {
  subnet_id      = aws_subnet.MC-Subnet-1.id
  route_table_id = aws_route_table.MC-Route-Table.id
}

resource "aws_security_group" "MC-Security-Group" {
  name        = "MC-Security-Group"
  description = "MC Security Group"
  vpc_id      = aws_vpc.MC-EKS-VPC.id

  tags = {
    Name = "MC-Security-Group"
  }
}

resource "aws_security_group_rule" "MC-Allow-HTTPS-Web" {
  description       = "Allow Inbound HTTPS Web Traffic"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.MC-Security-Group.id
}

resource "aws_security_group_rule" "MC-Allow-HTTP-Web" {
  description       = "Allow Inbound HTTP Web Traffic"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.MC-Security-Group.id
}

resource "aws_security_group_rule" "MC-Allow-SSH-Web" {
  description       = "Allow Inbound SSH Web Traffic"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.MC-Security-Group.id
}

resource "aws_security_group_rule" "MC-Outbound-ipv6" {
  description       = "Allow Outbound Traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.MC-Security-Group.id
}

resource "aws_network_interface" "MC-NIC" {
  subnet_id       = aws_subnet.MC-Subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.MC-Security-Group.id]
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.MC-NIC.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.MC-Gateway]
}

resource "aws_instance" "Minecraft-Server" {
    # RHEL x86_64 Minecraft Server
    # Specs: t2.large, 2x vCPUs, 8.0 GiB RAM
    ami             = "ami-0537d5849fff83412"
    instance_type   = "t2.large"
    availability_zone = "us-east-1a"
    key_name = "MC-EKS"

  network_interface {
    network_interface_id = aws_network_interface.MC-NIC.id
    device_index         = 0
  }

  # User Input on Startup - Work in Progress
  # user_data = <<-EOF
  #    #!/bin/bash
  #    sudo yum update
  # EOF

    tags = {
        Name = "Linux MC Server"
    }
}

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "18.11.0"
#   # insert the 15 required variables here
# }



