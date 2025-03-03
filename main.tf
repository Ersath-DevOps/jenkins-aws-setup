######## Terraform  ########
provider "aws" {
  region = "us-east-1a"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  map_public_ip_on_launch = false
}

resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.my_vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
######## instance ##########
resource "aws_instance" "app_server" {
  ami                    = "ami-0c7af5fe939f2677f"
  instance_type          = "t2.micro"
  subnet_id             = aws_subnet.private_subnet.id
  security_groups       = [aws_security_group.app_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=my-cluster" >> /etc/ecs/ecs.config
              yum install -y docker
              systemctl start docker
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
              docker run -d -p 80:80 ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo}:latest
              EOF
}
########################
