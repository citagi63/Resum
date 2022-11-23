resource "aws_ecs_cluster" "conductor" {
    name = var.cluster_name
}
