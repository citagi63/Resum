variable "cluster_name" {
  type        = string
  default     = "conductor_cluster"
  description = "Name the cluster"
}
variable "ecr_repo" {
    type = string
    default = "conductor-img"
}
variable "container_port" {
    type = number
    default = 80
}
variable "environment" {
    type = string
}
variable "aws_security_group_ecs_tasks_id"{
    type = string
    default = ""
}
variable "private_subnet_ids" {
    type = list(string)
}
variable region {}
variable "vpc_id" {
    type = string
}
