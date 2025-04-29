provider "aws" {
  region = var.region
}

# Data source to fetch VPC ID from subnets
data "aws_subnet" "selected_subnets" {
  id = var.subnets[0]  # Using the first subnet to get the VPC ID
}

# Create the CloudWatch Log Group
resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = var.log_group
  retention_in_days = 7  # Optional: Set retention policy (e.g., 7 days)
}

# ECS Task Definition for NGINX container with CloudWatch Logs
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([{
    name      = "nginx"
    image     = var.container_image
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "nginx"
      }
    }
  }])
}

# Create a new target group of type IP
resource "aws_lb_target_group" "nginx_target_group" {
  name     = var.tg_name
  port     = 90
  protocol = "HTTP"
  vpc_id   = data.aws_subnet.selected_subnets.vpc_id  # Fetching VPC ID from the first subnet

  target_type = "ip"
}

# Add a listener on port 90 to the existing Load Balancer 'imtech'
resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = var.load_balancer_arn
  port              = 90
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }
}

# ECS Service using Fargate and connecting to the new target group
resource "aws_ecs_service" "nginx_service" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.sgs
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
    container_name   = "nginx"
    container_port   = 80
  }
}

