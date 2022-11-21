output domain_name {
  value       =  aws_elasticsearch_domain.opensearch.domain_name
}
#output master_name {
    #value = aws_elasticsearch_domain.master_user_options.master_user_name
#}
#output subnet_id {
    #value = aws_elasticsearch_domain.vpc_options.subnet_ids
#}
#output aws_security_group{
    #value = aws_elasticsearch_domain.vpc_options.security_group_ids
#}
#output volume_size {
    #value = aws_elasticsearch_domain.ebs_options.volume_size.id
#}
#output volume_type {
    #value = aws_elasticsearch_domain.ebs_options.volume_type
#}
