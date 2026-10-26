###############################################################################
# Network Outputs
###############################################################################
output "vpc_id" {
  description = "VPC ID used by the cluster"
  value       = local.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by the cluster"
  value       = local.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs (create_vpc = true only)"
  value       = var.create_vpc ? module.vpc[0].public_subnet_ids : []
}

output "nat_public_ips" {
  description = "NAT gateway public IPs (create_vpc = true only)"
  value       = var.create_vpc ? module.vpc[0].nat_public_ips : []
}

###############################################################################
# Bastion Outputs
###############################################################################
output "bastion_instance_id" {
  description = "Bastion instance ID"
  value       = try(module.bastion[0].instance_id, null)
}

output "bastion_ssm_command" {
  description = "Command to open a Session Manager shell on the bastion"
  value       = try("aws ssm start-session --region ${var.region} --target ${module.bastion[0].instance_id}", null)
}

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
