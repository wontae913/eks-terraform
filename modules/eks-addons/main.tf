data "aws_partition" "current" {}

###############################################################################
# EBS CSI Driver IAM Role (Pod Identity)
###############################################################################
resource "aws_iam_role" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name = "${var.name}-role-eks-ebs-csi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy" "ebs_csi_kms" {
  count = var.enable_ebs_csi_driver && var.ebs_kms_key_arn != null ? 1 : 0

  name = "ebs-csi-kms"
  role = aws_iam_role.ebs_csi[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      Resource = var.ebs_kms_key_arn
    }]
  })
}

###############################################################################
# VPC CNI IAM Role (Pod Identity)
###############################################################################
resource "aws_iam_role" "vpc_cni" {
  name = "${var.name}-role-eks-vpc-cni"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

###############################################################################
# Add-ons
###############################################################################
data "aws_eks_addon_version" "this" {
  for_each = local.addons

  addon_name         = each.key
  kubernetes_version = var.cluster_version
  most_recent        = true
}

locals {
  # 노드가 Ready 되려면 먼저 필요 (bootstrap_self_managed_addons = false 라 기본 설치 없음)
  before_compute_addons = {
    "eks-pod-identity-agent" = { service_account = null, role_arn = null }
    "vpc-cni"                = { service_account = "aws-node", role_arn = aws_iam_role.vpc_cni.arn }
    "kube-proxy"             = { service_account = null, role_arn = null }
  }

  # 노드에 스케줄되어야 Active 되므로 노드 그룹 이후 생성
  after_compute_addons = merge(
    {
      "coredns" = { service_account = null, role_arn = null }
    },
    var.enable_ebs_csi_driver ? {
      "aws-ebs-csi-driver" = { service_account = "ebs-csi-controller-sa", role_arn = aws_iam_role.ebs_csi[0].arn }
    } : {}
  )

  addons = merge(local.before_compute_addons, local.after_compute_addons)
}

resource "aws_eks_addon" "before_compute" {
  for_each = local.before_compute_addons

  cluster_name  = var.cluster_name
  addon_name    = each.key
  addon_version = lookup(var.addon_versions, each.key, data.aws_eks_addon_version.this[each.key].version)

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  dynamic "pod_identity_association" {
    for_each = each.value.role_arn != null ? [1] : []
    content {
      service_account = each.value.service_account
      role_arn        = each.value.role_arn
    }
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.vpc_cni]
}

# 노드 그룹 생성 완료 신호 (var.node_group_names 가 알려져야 after_compute 애드온 생성)
resource "terraform_data" "compute_ready" {
  input = var.node_group_names
}

resource "aws_eks_addon" "this" {
  for_each = local.after_compute_addons

  cluster_name  = var.cluster_name
  addon_name    = each.key
  addon_version = lookup(var.addon_versions, each.key, data.aws_eks_addon_version.this[each.key].version)

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  dynamic "pod_identity_association" {
    for_each = each.value.role_arn != null ? [1] : []
    content {
      service_account = each.value.service_account
      role_arn        = each.value.role_arn
    }
  }

  tags = var.tags

  depends_on = [
    aws_eks_addon.before_compute,
    terraform_data.compute_ready,
  ]
}
