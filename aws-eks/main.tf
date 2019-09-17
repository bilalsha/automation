provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

data "aws_vpc" "default" {
  default = true
}

# This `label` is needed to prevent `count can't be computed` errors
module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.11/master"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
  enabled    = "${var.enabled}"
}

# This `label` is needed to prevent `count can't be computed` errors
module "cluster_label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.11/master"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = ["${compact(concat(var.attributes, list("cluster")))}"]
  tags       = "${var.tags}"
  enabled    = "${var.enabled}"
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking
  tags = "${merge(var.tags, map("kubernetes.io/cluster/${module.label.id}", "shared"))}"
}

# https://github.com/cloudposse/terraform-aws-vpc
module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=0.11/master"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  attributes = "${var.attributes}"
  tags       = "${local.tags}"
  cidr_block = "${var.vpc_cidr_block}"
}

module "subnets" {
  source              = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=0.11.0"
  availability_zones  = ["${var.availability_zones}"]
  namespace           = "${var.namespace}"
  stage               = "${var.stage}"
  name                = "${var.name}"
  attributes          = "${var.attributes}"
  tags                = "${merge(var.tags,
                            map(
                              "kubernetes.io/cluster/${var.name}", "shared",
                              "kubernetes.io/role/internal-elb", ""
                            )
                          )}"
  region              = "${var.region}"
  vpc_id              = "${module.vpc.vpc_id}"
  igw_id              = "${module.vpc.igw_id}"
  cidr_block          = "${module.vpc.vpc_cidr_block}"
  nat_gateway_enabled = "true"

  #tags  :  kubernetes.io/cluster/<CLUSTERNAME>  = shared
  # kubernetes.io/role/elb 1
}


module "eks_cluster" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=master"
  namespace               = "${var.namespace}"
  stage                   = "${var.stage}"
  name                    = "${var.name}"
  attributes              = "${var.attributes}"
  tags                    = "${var.tags}"
  vpc_id                  = "${module.vpc.vpc_id}"
  kubernetes_version      = "${var.kubernetes_version}"

  subnet_ids              = ["${module.subnets.public_subnet_ids}"]
  allowed_security_groups = ["${var.allowed_security_groups_cluster}"]

  # `workers_security_group_count` is needed to prevent `count can't be computed` errors
  workers_security_group_ids   = ["${module.eks_workers.security_group_id}"]
  workers_security_group_count = 1

  allowed_cidr_blocks = ["${var.allowed_cidr_blocks_cluster}"]
  enabled             = "${var.enabled}"
}

module "eks_workers" {
  source                             = "git::https://github.com/cloudposse/terraform-aws-eks-workers.git?ref=master"
  namespace                          = "${var.namespace}"
  stage                              = "${var.stage}"
  name                               = "${var.name}"
  attributes                         = "${var.attributes}"
  tags                               = "${var.tags}"
  image_id                           = "${var.image_id}"
  eks_worker_ami_name_filter         = "${var.eks_worker_ami_name_filter}"
  instance_type                      = "${var.instance_type}"
  vpc_id                             = "${module.vpc.vpc_id}"
  subnet_ids                         = ["${module.subnets.private_subnet_ids}"]
  health_check_type                  = "${var.health_check_type}"
  min_size                           = "${var.min_size}"
  max_size                           = "${var.max_size}"
  wait_for_capacity_timeout          = "${var.wait_for_capacity_timeout}"
  associate_public_ip_address        = "${var.associate_public_ip_address}"
  cluster_name                       = "${module.cluster_label.id}"
  cluster_endpoint                   = "${module.eks_cluster.eks_cluster_endpoint}"
  cluster_certificate_authority_data = "${module.eks_cluster.eks_cluster_certificate_authority_data}"
  cluster_security_group_id          = "${module.eks_cluster.security_group_id}"
  allowed_security_groups            = ["${var.allowed_security_groups_workers}"]
  allowed_cidr_blocks                = ["${var.allowed_cidr_blocks_workers}"]
  enabled                            = "${var.enabled}"
  key_name                           = "${var.eks_nodes_ssh_key_name}"

  # Auto-scaling policies and CloudWatch metric alarms
  autoscaling_policies_enabled           = "${var.autoscaling_policies_enabled}"
  cpu_utilization_high_threshold_percent = "${var.cpu_utilization_high_threshold_percent}"
  cpu_utilization_low_threshold_percent  = "${var.cpu_utilization_low_threshold_percent}"
}

resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_vpc_id = "${data.aws_vpc.default.id}"   # default vpc id

  vpc_id = "${module.vpc.vpc_id}" #vpc2
  auto_accept = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags {
    Name = "Bridging back to DEFAULT"
    Namespace = "${var.namespace}"
  }
}


resource "aws_route" "default_to_eks_peering_route" {
  route_table_id         = "${data.aws_vpc.default.main_route_table_id}"  # default vpc main route table id

  destination_cidr_block = "${module.vpc.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.vpc_peering.id}"
}

resource "aws_route" "eks_to_default_peering_route" {
  route_table_id         = "${module.vpc.vpc_main_route_table_id}"  # default vpc's masgter route
  destination_cidr_block = "${data.aws_vpc.default.cidr_block}"
  vpc_peering_connection_id ="${aws_vpc_peering_connection.vpc_peering.id}"
}

resource "aws_route" "private_vpn_route_entry" {
  //module.subnets.private_route_table_ids has the same number of element with var.availability_zones
  count = "${length(var.availability_zones)}"
  route_table_id            = "${module.subnets.private_route_table_ids[count.index]}"
  destination_cidr_block = "${data.aws_vpc.default.cidr_block}"
  vpc_peering_connection_id ="${aws_vpc_peering_connection.vpc_peering.id}"
}

resource "aws_route" "public_vpn_route_entry" {
  //module.subnets.public_route_table_ids has always 1 element
  route_table_id            = "${module.subnets.public_route_table_ids[0]}"
  destination_cidr_block = "${data.aws_vpc.default.cidr_block}"
  vpc_peering_connection_id ="${aws_vpc_peering_connection.vpc_peering.id}"
}


#
# Add an inbound rule, to allow the Default VPC (i.e.: the VPN) , access to the worker nodes
#
resource "aws_security_group_rule" "allow_all_from_default" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  cidr_blocks = ["${data.aws_vpc.default.cidr_block}"]
  security_group_id = "${module.eks_workers.security_group_id}"
}