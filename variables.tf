###############################################################################
# Basic Configuration
###############################################################################
variable "project" {
  description = "Project name"
  type        = string
  default     = "eks-test"
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "environment must be one of: dev, stg, prd."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

###############################################################################
# Network
###############################################################################
variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for control plane ENIs and worker nodes (at least 2 AZs)"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "EKS requires subnets in at least 2 availability zones."
  }
}

###############################################################################
# Cluster
###############################################################################
variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.36"
}

variable "support_type" {
  description = "EKS version support policy (STANDARD | EXTENDED)"
  type        = string
  default     = "STANDARD"
}

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API endpoint is publicly accessible"
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access_cidrs" {
  description = "CIDR blocks allowed to reach the private API endpoint (VPC, on-premises)"
  type        = list(string)
  default     = []
}

variable "access_entries" {
  description = "EKS access entries (key → principal ARN, access policy name, optional namespaces)"
  type = map(object({
    principal_arn = string
    policy_name   = string
    namespaces    = optional(list(string), [])
  }))
  default = {}
}

variable "log_retention_days" {
  description = "Control plane log CloudWatch retention period in days"
  type        = number
  default     = 90
}

###############################################################################
# KMS
###############################################################################
variable "secrets_kms_key_arn" {
  description = "KMS key ARN for Kubernetes secrets encryption (null = disabled)"
  type        = string
  default     = null
}

variable "cloudwatch_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Logs encryption"
  type        = string
  default     = null
}

variable "ebs_kms_key_arn" {
  description = "KMS key ARN for EBS volume encryption (null = AWS managed key)"
  type        = string
  default     = null
}

###############################################################################
# Node Groups
###############################################################################
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

###############################################################################
# Add-ons
###############################################################################
variable "addon_versions" {
  description = "Pinned add-on versions (add-on name → version)"
  type        = map(string)
  default     = {}
}

variable "enable_ebs_csi_driver" {
  description = "Whether to install the EBS CSI driver add-on"
  type        = bool
  default     = true
}
