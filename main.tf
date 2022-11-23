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
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = "${aws_iam_role.ecs_task_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
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
  cluster         = var.cluster_name_id
  task_definition = aws_ecs_task_definition.conductor_task.family
  desired_count   = 2
  launch_type     = "FARGATE"
    network_configuration {
    security_groups = [var.aws_security_group_ecs_tasks_id]
    subnets         = var.private_subnet_ids
  }
  depends_on = [
    aws_ecs_task_definition.conductor_task,
  ]
}
