#module "vpc" {
 # source = "../vpc"
#}
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}
resource "aws_elasticsearch_domain" "opensearch" {
  domain_name           = var.domain_name
  elasticsearch_version = var.elasticsearch_version
  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    #zone_awareness_enabled = "true"
    #master_user_name = var.master_user_name
   # master_user_password = var.master_user_password
  }
    ebs_options {
    ebs_enabled = var.ebs_enabled
    volume_size = var.volume_size
    volume_type = var.volume_type
  }
  node_to_node_encryption {
    enabled = true
  }
  
  #vpc_options {
  # subnet_ids = [
     #data.aws_subnet_ids.subnet-0af28d062f242cfcd.id
   # ]
   # security_group_ids = [data.aws_security_group.sg-0b862a24f76060a7d]

# }
   domain_endpoint_options {
    enforce_https = var.enforce_https
    tls_security_policy = var.tls_security_policy
  }
  advanced_security_options {
    enabled = true
     master_user_options {
      master_user_arn = "arn:aws:iam::375566442973:user/master"
  }
  }
  encrypt_at_rest {
    enabled    = "true"
    kms_key_id = ""
  }
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }
  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:domain/${var.domain_name}"
        }
    ]
}
CONFIG
  depends_on      = [aws_iam_service_linked_role.es]
}
