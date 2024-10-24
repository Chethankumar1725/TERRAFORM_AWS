terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.69.0"
    }
  }
}
provider "aws" {
  profile = "default"
  region  = "us-east-2"
}
resource "aws_cloudwatch_dashboard" "EC2_Dashboard" {
  dashboard_name = "EC2-Dashboard"
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "explorer",
            "width": 24,
            "height": 15,
            "x": 0,
            "y": 0,
            "properties": {
                "metrics": [
                    {
                        "metricName": "CPUUtilization",
                        "resourceType": "AWS::EC2::Instance",
                        "stat": "Maximum"
                    }
                ],
                "aggregateBy": {
                    "key": "InstanceType",
                    "func": "MAX"
                },
                "labels": [
                    {
                        "key": "State",
                        "value": "running"
                    }
                ],
                "widgetOptions": {
                    "legend": {
                        "position": "bottom"
                    },
                    "view": "timeSeries",
                    "rowsPerPage": 8,
                    "widgetsPerRow": 2
                },
                "period": 60,
                "title": "Running EC2 Instances CPUUtilization"
            }
        }
    ]
}
EOF
}
module "metric_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 2.0"
  alarm_name          = "EC2_CPU_Usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 70
  period              = 60
  unit                = "Count"
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  statistic   = "Average"
  alarm_actions = ["arn:aws:sns:us-east-2:585584209241:cpu_utilization"]
}
resource "aws_launch_template" "EC2_Launch_Template" {
  name_prefix   = "EC2-Launch-Template"
  image_id      = "ami-050cd642fd83388e4"
  instance_type = "t2.micro"
}
resource "aws_autoscaling_group" "EC2_AutoScaling_Group" {
  availability_zones = ["us-east-2b"]
  desired_capacity   = 1
  max_size           = 5
  min_size           = 1
  launch_template {
    id      = aws_launch_template.EC2_Launch_Template.id
    version = "$Latest"
  }
  depends_on = [
    aws_launch_template.EC2_Launch_Template,
  ]
}
 
resource "aws_autoscaling_policy" "EC2_AutoScaling_Policy" {
  name                   = "EC2-AutoScaling-Policy"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.EC2_AutoScaling_Group.name
  depends_on = [
    aws_autoscaling_group.EC2_AutoScaling_Group,
  ]
}
resource "aws_cloudwatch_metric_alarm" "EC2_metric_alarm" {
  alarm_name          = "EC2-metric-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  depends_on = [
    aws_autoscaling_group.EC2_AutoScaling_Group,
  ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.EC2_AutoScaling_Group.name
  }
 
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.EC2_AutoScaling_Policy.arn]
}
resource "aws_cloudwatch_metric_stream" "main" {
  name          = "my-metric-stream"
  role_arn      = aws_iam_role.metric_stream_to_firehose.arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.s3_stream.arn
  output_format = "json"
  include_filter {
    namespace = "AWS/EC2"
  }
  include_filter {
    namespace = "AWS/EBS"
  }
}
resource "aws_iam_role" "metric_stream_to_firehose" {
  name = "metric_stream_to_firehose_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "streams.metrics.cloudwatch.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "metric_stream_to_firehose" {
  name = "default"
  role = aws_iam_role.metric_stream_to_firehose.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "firehose:PutRecord",
                "firehose:PutRecordBatch"
            ],
            "Resource": "${aws_kinesis_firehose_delivery_stream.s3_stream.arn}"
        }
    ]
}
EOF
}
resource "aws_s3_bucket" "bucket" {
  bucket = "test-metric-stream-bucket1725"
  acl    = "private"
}
resource "aws_iam_role" "firehose_to_s3" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "firehose_to_s3" {
  name = "default"
  role = aws_iam_role.firehose_to_s3.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.bucket.arn}",
                "${aws_s3_bucket.bucket.arn}/*"
            ]
        }
    ]
}
EOF
}
resource "aws_kinesis_firehose_delivery_stream" "s3_stream" {
  name        = "metric-stream-test-stream"
  destination = "s3"
  s3_configuration {
    role_arn   = aws_iam_role.firehose_to_s3.arn
    bucket_arn = aws_s3_bucket.bucket.arn
  }
}
resource "aws_cloudwatch_composite_alarm" "EC2_and_EBS" {
  alarm_description = "Composite alarm that monitors CPUUtilization and EBS Volume Write Operations"
  alarm_name        = "EC2_&EBS_Composite_Alarm"
  alarm_actions = [aws_sns_topic.EC2_and_EBS_topic.arn]
  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.EC2_CPU_Usage_Alarm.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.EBS_WriteOperations.alarm_name})"
 
  depends_on = [
    aws_cloudwatch_metric_alarm.EC2_CPU_Usage_Alarm,
    aws_cloudwatch_metric_alarm.EBS_WriteOperations,
    aws_sns_topic.EC2_and_EBS_topic,
    aws_sns_topic_subscription.EC2_and_EBS_Subscription
  ]
}
 
resource "aws_cloudwatch_metric_alarm" "EC2_CPU_Usage_Alarm" {
  alarm_name          = "EC2_CPU_Usage_Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization exceeding 70%"
}
 
resource "aws_cloudwatch_metric_alarm" "EBS_WriteOperations" {
  alarm_name          = "EBS_WriteOperations"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "VolumeReadOps"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "This monitors the average read operations on EBS Volumes in a specified period of time"
}
 
resource "aws_sns_topic" "EC2_and_EBS_topic" {
  name = "EC2_and_EBS_topic"
}
resource "aws_sns_topic_subscription" "EC2_and_EBS_Subscription" {
  topic_arn = aws_sns_topic.EC2_and_EBS_topic.arn
  protocol  = "email"
  endpoint  = "chethangowda2935@gmail.com"
  depends_on = [
    aws_sns_topic.EC2_and_EBS_topic
  ]
}