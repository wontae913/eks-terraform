variable "name" {
  description = "Resource name prefix"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used in kubernetes.io/cluster/<name> subnet tags"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block (/16 recommended)"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 16
    error_message = "vpc_cidr must be a valid CIDR of /16 or larger (subnets are carved as /19 and /24)."
  }
}

variable "azs" {
  description = "Availability zones (2-4)"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2 && length(var.azs) <= 4
    error_message = "azs must contain 2 to 4 availability zones."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one per AZ"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
