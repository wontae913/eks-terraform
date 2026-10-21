output "node_role_arn" {
  description = "Worker node IAM role ARN"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Worker node IAM role name"
  value       = aws_iam_role.node.name
}

output "node_group_names" {
  description = "Managed node group name map"
  value       = { for k, v in aws_eks_node_group.this : k => v.node_group_name }
}
