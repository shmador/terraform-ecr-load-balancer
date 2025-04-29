variable "subnets" {
  type = list(string)
  default = [ 
    "subnet-01e6348062924d048",
    "subnet-088b7d937a4cd5d85",
    ]
}

variable "service_name" {
  type = string
  default = "dor-service"
}

variable "cluster_name" {
  type = string
  default = "imtech"
}

variable "tg_name" {
  type = string
  default = "dor-target-group"
}

variable "region" {
  type = string
  default = "il-central-1"
}

variable "log_group" {
  type = string
  default = "/ecs/nginx-logs"
}

variable "container_image" {
  type = string
  default = "314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/nginx:latest"
}

variable "execution_role_arn" {
  type = string
  default = "arn:aws:iam::314525640319:role/ecsTaskExecutionRole"
}

variable "load_balancer_arn" {
  type = string
  default = "arn:aws:elasticloadbalancing:il-central-1:314525640319:loadbalancer/app/imtec/dd67eee2877975d6"
}