output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.this.version
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded cluster CA certificate"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "EKS-managed cluster security group ID (attached to control plane and managed nodes)"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "additional_security_group_id" {
  description = "Additional control plane security group ID"
  value       = aws_security_group.cluster.id
}

output "oidc_provider_arn" {
  description = "IRSA OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
