project     = "eks-test"
environment = "dev"
region      = "ap-northeast-2"

###############################################################################
# Network
# create_vpc = true  : VPC/서브넷/NAT 신규 생성
# create_vpc = false : 기존 VPC 사용 → vpc_id, private_subnet_ids 지정
###############################################################################
create_vpc         = true
vpc_cidr           = "10.0.0.0/16"
azs                = ["ap-northeast-2a", "ap-northeast-2c"]
single_nat_gateway = true

# vpc_id             = "vpc-xxxxxxxxxxxxxxxxx"
# private_subnet_ids = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb"]

###############################################################################
# Bastion (public 서브넷, 기본은 SSM 접속만 / inbound 없음)
###############################################################################
enable_bastion            = true
bastion_instance_type     = "t3.micro"
bastion_key_name          = null
bastion_ssh_allowed_cidrs = []

###############################################################################
# Cluster
###############################################################################
cluster_version               = "1.36"
endpoint_public_access        = false
endpoint_public_access_cidrs  = []
endpoint_private_access_cidrs = ["10.0.0.0/16"]
log_retention_days            = 7

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
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    min_size       = 1
    max_size       = 3
    desired_size   = 2
  }
}
