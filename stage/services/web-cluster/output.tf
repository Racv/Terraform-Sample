output "alb_dns_name" {
  value = aws_lb.ravi-lb.dns_name
  description = "domain name of load balancer"
}
