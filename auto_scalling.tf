
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





autoscaling new
provider "aws" {
  region = "us-west-2"
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
resource "aws_launch_template" "app" {
  name_prefix   = "app-launch-template-"
  image_id      = "ami-07c5ecd8498c59db5"  # Replace with a valid AMI ID
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "app" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier = [aws_subnet.subnet1.id]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"  # You can also specify a specific version
  }

  tag {
    key                 = "Name"
    value               = "autoscaled-app-instance"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment      = 1
  adjustment_type       = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment      = -1
  adjustment_type       = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.app.name
}
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods   = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}
