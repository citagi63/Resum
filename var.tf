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
variable "private_subnet_ids" {
    type = list(string)
}
variable region {}
variable "vpc_id" {
    type = string
}
variable "ingress_rules" {
  default     = {
    "description" = ["For HTTP", "For SSH"]
    "from_port"   = ["80", "5000"]
    "to_port"     = ["80", "22"]
    "protocol"    = ["tcp", "tcp"]
    "cidr_blocks" = ["0.0.0.0/0", "0.0.0.0/0"]
  }
  type        = map(list(string))
  description = "Security group rules"
}
