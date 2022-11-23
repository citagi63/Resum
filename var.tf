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
