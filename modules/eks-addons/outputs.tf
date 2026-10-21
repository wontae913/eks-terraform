output "addon_versions" {
  description = "Installed add-on version map"
  value       = { for k, v in aws_eks_addon.this : k => v.addon_version }
}

output "ebs_csi_role_arn" {
  description = "EBS CSI driver IAM role ARN"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi[0].arn : null
}
