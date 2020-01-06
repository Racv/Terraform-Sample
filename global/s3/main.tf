
provider "aws" {
  region = "us-east-2"
}

//setting up baackend for storing state information

terraform {
    backend "s3" {
        bucket = "my-first-s3-bucket-for-state"
        key = "global/s3/terraform.state"
        region = "us-east-2"

        dynamodb_table = "my-irst-dynamo-db-for-locks"
        encrypt = true
    }
}


resource "aws_s3_bucket" "terraform_state" {
    bucket = "my-first-s3-bucket-for-state"

    #prevent accidental deletion
    lifecycle {
        prevent_destroy = true
    } 

    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
  }
}


resource "aws_dynamodb_table" "terraform_locks" {
    name = "my-irst-dynamo-db-for-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
  
}





