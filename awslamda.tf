provider "aws" { 

  region                   = "eu-central-1" 

} 

  

resource "aws_iam_role" "lambda_role" { 

 name   = "terraform_aws_lambda_role" 

 assume_role_policy = <<EOF 

{ 

  "Version": "2012-10-17", 

  "Statement": [ 

    { 

      "Action": "sts:AssumeRole", 

      "Principal": { 

        "Service": "lambda.amazonaws.com" 

      }, 

      "Effect": "Allow", 

      "Sid": "" 

    } 

  ] 

} 

EOF 

} 

  

# IAM policy for logging from a lambda 

  

resource "aws_iam_policy" "iam_policy_for_lambda" { 

  

  name         = "aws_iam_policy_for_terraform_aws_lambda_role" 

  path         = "/" 

  description  = "AWS IAM Policy for managing aws lambda role" 

  policy = <<EOF 

{ 

  "Version": "2012-10-17", 

  "Statement": [ 

    { 

      "Action": [ 

        "logs:CreateLogGroup", 

        "logs:CreateLogStream", 

        "logs:PutLogEvents" 

      ], 