
#aws_launch_template
provider "aws" {
  region = "us-east-1" # Change this to your preferred AWS region
}
 
resource "aws_launch_template" "terraform" {
  name = "terraform-launch-template"
instance_type = "t2.micro"
  key_name      = "docker"
  image_id      = "ami-0ddc798b3f1a5117e"
 
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Hello, World!" > /var/tmp/hello.txt
  EOF
  )
 
  // other configurations...
}
 
resource "aws_vpc" "VPC-1" {
  cidr_block = "10.0.0.0/16"
 
  tags = {
    Name = "MyVPC"
  }
}
 
resource "aws_subnet" "publicsubnet1" {
  vpc_id     = aws_vpc.VPC-1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
 
  tags = {
    Name = "PublicSubnet1"
  }
}