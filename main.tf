###############################################################################
# VPC (create_vpc = false 면 기존 VPC의 vpc_id / private_subnet_ids 사용)
###############################################################################
module "vpc" {
  source = "./modules/vpc"
  count  = var.create_vpc ? 1 : 0

  name               = local.name
  cluster_name       = local.cluster_name
  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  single_nat_gateway = var.single_nat_gateway

  tags = {}
}

###############################################################################
# EKS Cluster
###############################################################################
module "eks_cluster" {
  source = "./modules/eks-cluster"

  name            = local.name
  cluster_version = var.cluster_version
  vpc_id          = local.vpc_id
  subnet_ids      = local.private_subnet_ids

  endpoint_public_access        = var.endpoint_public_access
  endpoint_public_access_cidrs  = var.endpoint_public_access_cidrs
  endpoint_private_access_cidrs = var.endpoint_private_access_cidrs

  bootstrap_cluster_creator_admin_permissions = true
  access_entries                              = var.access_entries

  secrets_kms_key_arn    = var.secrets_kms_key_arn
  cloudwatch_kms_key_arn = var.cloudwatch_kms_key_arn
  log_retention_days     = var.log_retention_days
  support_type           = var.support_type

  tags = {}
}

###############################################################################
# Managed Node Groups
###############################################################################
module "eks_node_group" {
  source = "./modules/eks-node-group"

  name = local.name
  # vpc-cni / kube-proxy 설치 후 노드 생성 (없으면 노드가 NotReady 로 멈춤)
  cluster_name    = module.eks_addons.cluster_name
  subnet_ids      = local.private_subnet_ids
  ebs_kms_key_arn = var.ebs_kms_key_arn
  node_groups     = var.node_groups

  tags = {}
}

###############################################################################
# Bastion (public 서브넷, SSM Session Manager 접속 → kubectl)
###############################################################################
module "bastion" {
  source = "./modules/bastion"
  count  = var.create_vpc && var.enable_bastion ? 1 : 0

  name              = local.name
  vpc_id            = local.vpc_id
  subnet_id         = module.vpc[0].public_subnet_ids[0]
  cluster_name      = module.eks_cluster.cluster_name
  cluster_version   = module.eks_cluster.cluster_version
  instance_type     = var.bastion_instance_type
  key_name          = var.bastion_key_name
  ssh_allowed_cidrs = var.bastion_ssh_allowed_cidrs

  tags = {}
}

###############################################################################
# Add-ons
# vpc-cni / kube-proxy / pod-identity-agent : 노드 그룹 이전
# coredns / ebs-csi                         : 노드 그룹 이후 (node_group_names 로 대기)
###############################################################################
module "eks_addons" {
  source = "./modules/eks-addons"

  name                  = local.name
  cluster_name          = module.eks_cluster.cluster_name
  cluster_version       = module.eks_cluster.cluster_version
  node_group_names      = module.eks_node_group.node_group_names
  addon_versions        = var.addon_versions
  enable_ebs_csi_driver = var.enable_ebs_csi_driver
  ebs_kms_key_arn       = var.ebs_kms_key_arn

  tags = {}
}
