variable "name" {
  description = "Resource name prefix"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for worker nodes"
  type        = list(string)
}

variable "ebs_kms_key_arn" {
  description = "KMS key ARN for node root volume encryption (null = AWS managed key)"
  type        = string
  default     = null
}

variable "node_groups" {
  description = "Managed node group definitions (key → spec)"
  type = map(object({
    instance_types = list(string)
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
    min_size       = number
    max_size       = number
    desired_size   = number
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  }))
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
