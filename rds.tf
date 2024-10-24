#variable.tf
variable "access_key" {
    description = "Access key to AWS console"
}
variable "secret_key" {
    description = "Secret key to AWS console"
}
variable "region" {
    description = "AWS region"
}

#terraform.tfvars

region = "us-east-1"
access_key = "AKIAQEFWAYMCGPF5U5VB"
secret_key = "/+TstryGJ9ixzitvx8p5T9cMNaC6JjRjlQ4XZi9GPbc"

#main.tf
resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
#create a RDS Database Instance
resource "aws_db_instance" "myinstance" {
  engine               = "mysql"
  identifier           = "myrdsinstance"
  allocated_storage    =  20
  engine_version       = "8.0.39"
  instance_class       = "db.t3.micro"
  username             = "myrdsuser"
  password             = "myrdspassword"
  parameter_group_name = "default.mysql8.0"
vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]
  skip_final_snapshot  = true
  publicly_accessible =  true
}

#output.tf
output "security_group_id" {
value = aws_security_group.rds_sg.id
}
output "db_instance_endpoint" {
  value       = aws_db_instance.myinstance.endpoint
}