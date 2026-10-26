variable "name" {
  description = "Resource name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the bastion"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for kubeconfig"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version (kubectl minor version)"
  type        = string
}

variable "access_policy_name" {
  description = "EKS access policy granted to the bastion role"
  type        = string
  default     = "AmazonEKSClusterAdminPolicy"
}

variable "instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name for SSH (null = SSM only)"
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH (empty = no inbound)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
