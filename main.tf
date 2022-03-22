
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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.11.0"
  # insert the 15 required variables here
}

resource "aws_instance" "Minecraft-Server" {
    # RHEL x86_64 Minecraft Server
        # Specs: t2.large, 2x vCPUs, 8.0 GiB RAM
    ami             = "ami-0537d5849fff83412"
    instance_type   = "t2.large"
    tags = {
        Name = "Linux"
    }
}

