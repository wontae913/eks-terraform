output "addon_versions" {
  description = "Installed add-on version map"
  value       = { for k, v in merge(aws_eks_addon.before_compute, aws_eks_addon.this) : k => v.addon_version }
}

output "ebs_csi_role_arn" {
  description = "EBS CSI driver IAM role ARN"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi[0].arn : null
}

output "cluster_name" {
  description = "EKS cluster name, available only after before-compute add-ons (vpc-cni, kube-proxy) exist"
  value       = var.cluster_name

  depends_on = [aws_eks_addon.before_compute]
}
