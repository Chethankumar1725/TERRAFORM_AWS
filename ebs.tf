#provider.tf

provider "aws" {
    region = "us-east-1"
}

#variable.tf
variable "instance_type" {
  description = "This describes the instance type"
  type = string
  default = "t2.micro"
}

variable "ami_id" {
    description = "This describes the ami image"
    type = string
    default = "ami-0fff1b9a61dec8a5f"
}
variable "server_port" {
  description = "Server use this port for http requests"
  type = number
  default = 80
}

variable "ssh_port" {
  description = "Describes the ssh port"
  type = number
  default = 22
}

variable "availability_zone" {
  default = "us-east-1a"
}

#security_group.tf
resource "aws_security_group" "instance" {
    name = "terraform-SG"
    
    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this
    }
    
    ingress {
        from_port   = var.ssh_port
        to_port     = var.ssh_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this
    }
    
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    tags = {
        Name = "TerraformSG"
    }
}

#main.tf
resource "aws_instance" "server" {
  ami = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [ aws_security_group.instance.id ]
  availability_zone = var.availability_zone
  tags = {
    Name = "EC2-Server"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                echo "Terraform is easy!!!" > /var/www/html/index.html
                EOF
   user_data_replace_on_change = true 
}

#ebs_volume.tf

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs_vol.id
  instance_id = aws_instance.server.id
}

resource "aws_ebs_volume" "ebs_vol" {
  availability_zone = var.availability_zone
  size = 1
}

#output.tf
output "public_ip" {
    description = "The public IP address of the web server"
    value = aws_instance.server.public_ip
}
