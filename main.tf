resource "aws_security_group" "allow_alb" {
  name        = "allow_alb"
  description = "Allow Alb inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = ["Alb from ecs_cluster", "Allow conductor" "Allow api_gateway"]
    from_port        = [ 80 , 5000 , 8080 ]
    to_port          =  [ 80 , 5000 , 8080 ]
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_Alb"
  }
}
resource "aws_ecs_cluster" "conductor" {
    name = var.cluster_name
}
resource "aws_iam_role" "task_role" {
  name = "ecs_tasks-${var.cluster_name}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "ecs_tasks" {
  name = "main_ecs_tasks-${var.cluster_name}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "main_ecs_tasks" {
  name = "ecs_tasks-${var.cluster_name}-policy"
  role = aws_iam_role.ecs_tasks.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Resource": [
              "*"
            ],
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ssm:GetParameters",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:DescribeLogStreams"
            ]
        }
    ]

}
EOF
}
resource "aws_ecr_repository" "ecr_repo"{
    name= var.ecr_repo
}
resource "aws_ecs_task_definition" "conductor_task" {
    family = var.ecr_repo
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                      = 256
    memory                   = 512
    execution_role_arn      = aws_iam_role.task_role.arn
    task_role_arn            = aws_iam_role.ecs_tasks.arn
    container_definitions = jsonencode([{
    name        = "${var.cluster_name}-container-${var.environment}"
    image       = "nginx:latest"
    essential   = true
    environment = [{"name": "VARNAME", "value": var.environment}]
    portMappings = [{
        protocol      = "tcp"
        containerPort = var.container_port
        hostPort      = var.container_port
   }]
}])
}
resource "aws_lb" "alb" {
  name               = "alb-conductor"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.private_subnet_ids
  security_groups    = aws_security_group.allow_alb
  enable_cross_zone_load_balancing = true

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
  }
}
resource "aws_lb_target_group" "alb_tg" {
  depends_on  = [
    aws_lb.alb
  ]
  name        = "alb-${var.environment}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  connection_termination = false
}
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.container_port
  protocol    = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb_tg.id
    type             = "forward"
  }
}
resource "aws_ecs_service" "main" {
  name            = "conductor-service"
  cluster         = aws_ecs_cluster.conductor.name
  task_definition = aws_ecs_task_definition.conductor_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
    network_configuration {
    security_groups = [aws_security_group.allow_alb.id]
    subnets         = var.private_subnet_ids
  }
    load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    container_name   = "${var.cluster_name}-container-${var.environment}"
    container_port   = var.container_port
  }
  depends_on = [
    aws_ecs_task_definition.conductor_task,
  ]
}
