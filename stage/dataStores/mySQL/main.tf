provider aws {
    region = "us-east-2"
}

terraform {
    backend "s3" {
        bucket = "my-first-s3-bucket-for-state"
        key = "stage/dataStores/mySQL/terraform.tfstate"
        region = "us-east-2"

        dynamodb_table = "my-irst-dynamo-db-for-locks"
        encrypt = true
    }
}



resource "aws_db_instance" "my_sql_db" {
 identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  name                = "ravi_sample_database"
  username            = "admin"

  password =
    data.aws_secretsmanager_secret_version.db_password.secret_string
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "mysql-master-password-stage"
}