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
resource "aws_lb" "nlb" {
  name               = "nlb-${var.cluster_name}"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
  }
}
resource "aws_lb_target_group" "nlb_tg" {
  depends_on  = [
    aws_lb.nlb
  ]
  name        = "nlb-${var.environment}-tg"
  port        = var.container_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  connection_termination = true
}
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = var.container_port
  protocol    = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.nlb_tg.id
    type             = "forward"
  }
}
resource "aws_ecs_service" "main" {
  name            = "${var.cluster_name}-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.conductor_task.family
  desired_count   = 1
  launch_type     = "FARGATE"
    network_configuration {
    security_groups = [var.aws_security_group_ecs_tasks_id]
    subnets         = var.private_subnet_ids
  }
    load_balancer {
    target_group_arn = aws_lb_target_group.nlb_tg.arn
    container_name   = var.cluster_name
    container_port   = var.container_port
  }
  depends_on = [
    aws_ecs_task_definition.conductor_task,
  ]
}
