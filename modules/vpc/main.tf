locals {
  az_suffixes = [for az in var.azs : substr(az, -1, 1)]

  # private: /19 (VPC-CNI가 Pod마다 서브넷 IP를 할당하므로 크게), public: /24
  private_subnet_cidrs = [for i, _ in var.azs : cidrsubnet(var.vpc_cidr, 3, i)]
  public_subnet_cidrs  = [for i, _ in var.azs : cidrsubnet(var.vpc_cidr, 8, 240 + i)]

  nat_count = var.single_nat_gateway ? 1 : length(var.azs)

  cluster_tag = { "kubernetes.io/cluster/${var.cluster_name}" = "shared" }
}

###############################################################################
# VPC
###############################################################################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

###############################################################################
# Subnets
# public  : 인터넷 facing LB (kubernetes.io/role/elb)
# private : Control plane ENI, 노드, Pod, 내부 LB (kubernetes.io/role/internal-elb)
###############################################################################
resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, local.cluster_tag, {
    Name                     = "${var.name}-sn-pub-${local.az_suffixes[count.index]}"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, local.cluster_tag, {
    Name                              = "${var.name}-sn-pri-${local.az_suffixes[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

###############################################################################
# NAT Gateway (single_nat_gateway = true 면 첫 번째 AZ에 1개만)
###############################################################################
resource "aws_eip" "nat" {
  count = local.nat_count

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-eip-nat-${local.az_suffixes[count.index]}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${local.az_suffixes[count.index]}"
  })

  depends_on = [aws_internet_gateway.this]
}

###############################################################################
# Route Tables
###############################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-rt-pub"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(var.azs)

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-rt-pri-${local.az_suffixes[count.index]}"
  })
}

resource "aws_route" "private_nat" {
  count = length(var.azs)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.azs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

###############################################################################
# S3 Gateway Endpoint (무료, ECR 이미지 레이어 pull 트래픽의 NAT 비용 절감)
###############################################################################
data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-s3"
  })
}
