terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
resource "aws_iam_role" "example_role" {
  name = "examplerole"
 
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "example_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
resource "aws_iam_instance_profile" "example_profile" {
  name = "example_profile"
  role = aws_iam_role.example_role.name
}
resource "aws_instance" "example_instance" {
  ami           = "ami-06b21ccaeff8cd686"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.example_profile.name
 
  tags = {
    Name = "exampleinstance"
  }
}
data "aws_caller_identity" "current" {}
 
resource "aws_s3_bucket" "example_bucket" {
  bucket = "example-bucket-unique-12345"  # Ensure this is unique
  acl    = "private"
}
 
resource "aws_s3_bucket_policy" "example_bucket_policy" {
  bucket = aws_s3_bucket.example_bucket.id
 
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.example_role.name}"
        },
        "Action": [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::${aws_s3_bucket.example_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.example_bucket.bucket}/*"
        ]
      }
    ]
  })
}