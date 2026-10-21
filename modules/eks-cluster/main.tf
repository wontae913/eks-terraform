data "aws_partition" "current" {}

###############################################################################
# EKS Cluster IAM Role
###############################################################################
resource "aws_iam_role" "cluster" {
  name = "${var.name}-role-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

###############################################################################
# EKS Cluster Security Group (additional)
###############################################################################
resource "aws_security_group" "cluster" {
  name        = "${var.name}-sg-eks-cluster"
  description = "EKS control plane additional security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-sg-eks-cluster"
  })
}

resource "aws_vpc_security_group_ingress_rule" "cluster_api" {
  for_each = toset(var.endpoint_private_access_cidrs)

  security_group_id = aws_security_group.cluster.id
  description       = "Kubernetes API from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

###############################################################################
# Control Plane Logging
###############################################################################
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.name}-eks/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.cloudwatch_kms_key_arn

  tags = var.tags
}

###############################################################################
# EKS Cluster
###############################################################################
resource "aws_eks_cluster" "this" {
  name     = "${var.name}-eks"
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  enabled_cluster_log_types     = var.cluster_log_types
  bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.endpoint_public_access_cidrs : null
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  dynamic "encryption_config" {
    for_each = var.secrets_kms_key_arn != null ? [1] : []
    content {
      resources = ["secrets"]
      provider {
        key_arn = var.secrets_kms_key_arn
      }
    }
  }

  upgrade_policy {
    support_type = var.support_type
  }

  tags = merge(var.tags, {
    Name = "${var.name}-eks"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.cluster,
  ]
}

###############################################################################
# IRSA (OIDC Provider)
###############################################################################
resource "aws_iam_openid_connect_provider" "this" {
  url            = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]

  tags = merge(var.tags, {
    Name = "${var.name}-eks-oidc"
  })
}

###############################################################################
# Access Entries
###############################################################################
resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "this" {
  for_each = var.access_entries

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.this[each.key].principal_arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/${each.value.policy_name}"

  access_scope {
    type       = length(each.value.namespaces) > 0 ? "namespace" : "cluster"
    namespaces = length(each.value.namespaces) > 0 ? each.value.namespaces : null
  }
}
