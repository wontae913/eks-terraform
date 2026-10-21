project     = "eks-test"
environment = "prd"
region      = "ap-northeast-2"

###############################################################################
# Network (실제 값으로 교체)
###############################################################################
vpc_id             = "vpc-xxxxxxxxxxxxxxxxx"
private_subnet_ids = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb"]

###############################################################################
# Cluster
###############################################################################
cluster_version               = "1.36"
endpoint_public_access        = false
endpoint_public_access_cidrs  = []
endpoint_private_access_cidrs = ["10.0.0.0/16"]
log_retention_days            = 90

access_entries = {
  # admin = {
  #   principal_arn = "arn:aws:iam::123456789012:role/AdminRole"
  #   policy_name   = "AmazonEKSClusterAdminPolicy"
  # }
}

###############################################################################
# KMS
###############################################################################
secrets_kms_key_arn    = null
cloudwatch_kms_key_arn = null
ebs_kms_key_arn        = null

###############################################################################
# Node Groups
###############################################################################
node_groups = {
  default = {
    instance_types = ["m6i.xlarge"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    min_size       = 2
    max_size       = 6
    desired_size   = 2
  }
}
