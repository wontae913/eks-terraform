variable "name" {
  description = "Resource name prefix"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS control plane ENIs"
  type        = list(string)
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

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Grant cluster-admin to the IAM principal that creates the cluster"
  type        = bool
  default     = true
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

variable "secrets_kms_key_arn" {
  description = "KMS key ARN for Kubernetes secrets envelope encryption"
  type        = string
  default     = null
}

variable "cluster_log_types" {
  description = "Control plane log types to send to CloudWatch"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "log_retention_days" {
  description = "Control plane log CloudWatch retention period in days"
  type        = number
  default     = 90
}

variable "cloudwatch_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Logs encryption"
  type        = string
  default     = null
}

variable "support_type" {
  description = "EKS version support policy (STANDARD | EXTENDED)"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.support_type)
    error_message = "support_type must be one of: STANDARD, EXTENDED."
  }
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
