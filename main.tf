###############################################################################
# EKS Cluster
###############################################################################
module "eks_cluster" {
  source = "./modules/eks-cluster"

  name            = local.name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids

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

  name            = local.name
  cluster_name    = module.eks_cluster.cluster_name
  subnet_ids      = var.private_subnet_ids
  ebs_kms_key_arn = var.ebs_kms_key_arn
  node_groups     = var.node_groups

  tags = {}
}

###############################################################################
# Add-ons
# coredns / ebs-csi 는 노드가 있어야 Active 상태가 되므로 노드 그룹 이후 생성
###############################################################################
module "eks_addons" {
  source = "./modules/eks-addons"

  name                  = local.name
  cluster_name          = module.eks_cluster.cluster_name
  cluster_version       = module.eks_cluster.cluster_version
  addon_versions        = var.addon_versions
  enable_ebs_csi_driver = var.enable_ebs_csi_driver
  ebs_kms_key_arn       = var.ebs_kms_key_arn

  tags = {}

  depends_on = [module.eks_node_group]
}
