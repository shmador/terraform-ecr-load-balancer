provider "aws" {
  region = "il-central-1"
}

locals {
  subnets = [
    "subnet-01e6348062924d048",
   "subnet-088b7d937a4cd5d85",
  ]
}

# Data source to fetch VPC ID from subnets
data "aws_subnet" "selected_subnets" {
  id = local.subnets[0]  # Using the first subnet to get the VPC ID
}

# Create the CloudWatch Log Group
resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = "/ecs/nginx-logs"
  retention_in_days = 7  # Optional: Set retention policy (e.g., 7 days)
}

# ECS Task Definition for NGINX container with CloudWatch Logs
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::314525640319:role/ecsTaskExecutionRole"  # Using the provided role

  container_definitions = jsonencode([{
    name      = "nginx"
    image     = "314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/nginx:latest"
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
        "awslogs-group"         = "/ecs/nginx-logs"
        "awslogs-region"        = "il-central-1"
        "awslogs-stream-prefix" = "nginx"
      }
    }
  }])
}

# Create a new target group of type IP
resource "aws_lb_target_group" "nginx_target_group" {
  name     = "dor-target-group"
  port     = 90
  protocol = "HTTP"
  vpc_id   = data.aws_subnet.selected_subnets.vpc_id  # Fetching VPC ID from the first subnet

  target_type = "ip"
}

# Add a listener on port 90 to the existing Load Balancer 'imtech'
resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = "arn:aws:elasticloadbalancing:il-central-1:314525640319:loadbalancer/app/imtec/dd67eee2877975d6"  # Correct the ARN here
  port              = 90
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }
}

# ECS Service using Fargate and connecting to the new target group
resource "aws_ecs_service" "nginx_service" {
  name            = "dor-service"
  cluster         = "imtech"  # Existing ECS cluster
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.subnets
    security_groups = ["sg-0ac3749215afde82a"]  # Replace with your security group ID
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
    container_name   = "nginx"
    container_port   = 80
  }
}

