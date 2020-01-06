
provider "aws" {
    region = "us-east-2"
}

//fetching data

data "aws_vpc" "default" {
    default = true  
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}

//setting up backend for storing state information
terraform {
    backend "s3" {
        bucket = "my-first-s3-bucket-for-state"
        key = "stage/services/web-cluster/terraform.tfstate"
        region = "us-east-2"

        dynamodb_table = "my-irst-dynamo-db-for-locks"
        encrypt = true
    }
}





resource "aws_instance" "ravi_instance" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello Ravi" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    tags = {
        Name = "terraform-ravi"
    }
}

resource "aws_launch_configuration" "ravi_launch" {
    image_id = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello Ravi" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "ravi-asg" {
    launch_configuration = aws_launch_configuration.ravi_launch.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids

    target_group_arns = [aws_lb_target_group.alb-targets.arn]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-example-asg"
        propagate_at_launch = true
    }
  
}


resource "aws_security_group" "instance" {
  name = "terraform-ravi-instance"

  ingress{
      from_port = var.server_port
      to_port = var.server_port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "ravi-lb" {
    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "ravi-lb-listener" {
    load_balancer_arn = aws_lb.ravi-lb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: Page not found"
            status_code = 404
        }
    }
  
}

resource "aws_lb_target_group" "alb-targets" {
    name = "terraform-exapmle-asg"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
  
}



resource "aws_lb_listener_rule" "alb-listener" {
    listener_arn = aws_lb_listener.ravi-lb-listener.arn
    priority = 100


    condition {
        field = "path-pattern"
        values = ["*"]
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.alb-targets.arn
    }
  
}






