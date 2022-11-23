resource "aws_ecs_cluster" "conductor" {
    name = var.cluster_name
}
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ECS_exec_role"
 
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

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
 
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
resource "aws_iam_role_policy" "ecs_tasks" {
  name = "main_ecs_tasks-${var.cluster_name}-policy"
  role = aws_iam_role.ecs_task_role.id

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
    execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn            = aws_iam_role.ecs_task_role.arn
    container_definitions = jsonencode([{
    name        = "${var.cluster_name}-container-${var.environment}"
    image       = "ngnix:latest"
    essential   = true
    environment = [{"name": "VARNAME", "value": var.environment}]
    portMappings = [{
        protocol      = "tcp"
        containerPort = var.container_port
        hostPort      = var.container_port
   }]
}])
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
  depends_on = [
    aws_ecs_task_definition.conductor_task,
  ]
}
