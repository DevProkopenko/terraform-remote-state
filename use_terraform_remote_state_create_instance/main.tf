provider "aws" {
  region = "eu-central-1"
}
terraform {
  backend "s3" {
    bucket = "prokopenko-artsiom-terraform-bucket"
    key    = "dev/instance/terraform.tfstate"
    region = "eu-central-1"
  }
}
#----------------------------------------------------------------------------------
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "prokopenko-artsiom-terraform-bucket-now"
    key    = "dev/network/terraform.tfstate"
    region = "eu-central-1"
  }
}
data "aws_availability_zones" "available" {}
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
#----------------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name   = "Dynamic Security Group"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Dynamic SecurityGroup"
    Owner = "Prokopenko Art"
  }
}
resource "aws_instance" "web-server" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = data.terraform_remote_state.network.outputs.public_subnets_ids[0]
  user_data              = file("user_data.sh")
  tags = {
    Name = "webserver"
  }
}
#----------------------------------------------------------------------------------
