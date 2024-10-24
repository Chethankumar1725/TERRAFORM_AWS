provider "aws" {
  region = "us-west-2"
}
 
resource "aws_instance" "instance1" {
  ami           = "ami-0b029b1931b347543"
  instance_type = "t2.micro"
  tags = {
    name = "my-demo-instance"
  }
}