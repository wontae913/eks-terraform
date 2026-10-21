variable "name" {
  description = "Resource name prefix"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster Kubernetes version (used to resolve latest add-on versions)"
  type        = string
}

variable "addon_versions" {
  description = "Pinned add-on versions (add-on name → version). Unlisted add-ons use the latest compatible version"
  type        = map(string)
  default     = {}
}

variable "enable_ebs_csi_driver" {
  description = "Whether to install the EBS CSI driver add-on"
  type        = bool
  default     = true
}

variable "ebs_kms_key_arn" {
  description = "KMS key ARN used by the EBS CSI driver for encrypted volumes"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
