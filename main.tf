resource "aws_vpc" "conductor_vpc" {
    cidr_block       =  var.vpc_cidr_block
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "${var.vpc_tag_name}-${var.environment}"
    }
}
resource "aws_subnet" "conductor_public_subnet" {
    count =  var.number_of_public_subnets
    vpc_id = aws_vpc.conductor_vpc.id
    cidr_block = element(var.public_subnet_cidr_blocks, count.index)
    availability_zone = element(var.availability_zones, count.index)
    tags = {
        Name = "${var.public_subnet_tag_name}-${var.environment}"
    }         
}
resource "aws_subnet" "conductor_private_subnet" {
    count = var.number_of_private_subnets
    vpc_id =  aws_vpc.conductor_vpc.id
    cidr_block = element(var.private_subnet_cidr_blocks, count.index)
    availability_zone = element(var.availability_zones, count.index)

    tags = {
        Name = "${var.private_subnet_tag_name}-${var.environment}"
    }    
}
resource "aws_subnet" "conductor_private_subnet_db" {
    count = var.number_of_private_subnets_db
    vpc_id =  aws_vpc.conductor_vpc.id
    cidr_block = element(var.private_subnet_cidr_blocks_db, count.index)
    availability_zone = element(var.availability_zones, count.index)

    tags = {
        Name = "${var.private_subnet_tag_name}-db-${var.environment}"
    }    
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.conductor_vpc.id
}
resource "aws_eip" "elastic_ip" {
  vpc = true
  tags = {
    Name = "elastic_ip-dev"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.conductor_vpc.id
  tags = {
    Name = "public-route-table-${availability_zone}-route-table-public-${var.environment}"
  }
}
resource "aws_route_table_association" "igw_public_subnet_assoc" {
  route_table_id = aws_route_table.public_route_table[count.index].id
  subnet_id = aws_subnet.conductor_public_subnet[count.index].id 
  }
  resource "aws_route" "ig_public_subnet_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
}

