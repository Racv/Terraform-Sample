output "s3_bukcet_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "Arn of s3 bucket"
}

output "dynamo_db_name" {
    value = aws_dynamodb_table.terraform_locks.name
    description = "Name of dynamo db whihc is being used for locking"
}


