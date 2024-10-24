provider "aws" {
  region = "us-west-2"  # Set your desired region
}
 
resource "aws_s3_bucket" "buckt1725" {
  bucket = "buckt1725"  # Ensure this name is unique
}
 
resource "aws_s3_bucket_policy" "buckt1725_policy" {
  bucket = aws_s3_bucket.buckt1725.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.buckt1725.arn}/*"
      },
    ]
  })
}