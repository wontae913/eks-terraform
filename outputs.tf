###############################################################################
# Cluster Outputs
###############################################################################
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks_cluster.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks_cluster.cluster_arn
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded cluster CA certificate"
  value       = module.eks_cluster.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  description = "EKS-managed cluster security group ID"
  value       = module.eks_cluster.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "IRSA OIDC provider ARN"
  value       = module.eks_cluster.oidc_provider_arn
}

###############################################################################
# Node / Add-on Outputs
###############################################################################
output "node_role_arn" {
  description = "Worker node IAM role ARN"
  value       = module.eks_node_group.node_role_arn
}

output "node_group_names" {
  description = "Managed node group name map"
  value       = module.eks_node_group.node_group_names
}

output "addon_versions" {
  description = "Installed add-on version map"
  value       = module.eks_addons.addon_versions
}

output "kubeconfig_command" {
  description = "Command to update local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks_cluster.cluster_name}"
}
