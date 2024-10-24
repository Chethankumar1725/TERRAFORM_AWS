provider "aws" {

region = "us-west-2"

}


resource "aws_s3_bucket" "my_bucket" {

bucket = "devops2211"


versioning {

enabled = true

}


acl = "private"


tags = {

Name = "My bucket"

Environment = "Dev"

}

}