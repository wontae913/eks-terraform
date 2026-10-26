locals {
  region_short = {
    "ap-northeast-2" = "an2"
  }[var.region]

  name = "${var.project}-${var.environment}-${local.region_short}"

  # eks-cluster 모듈의 클러스터 이름 규칙과 동일해야 서브넷 태그가 맞음
  cluster_name = "${local.name}-eks"

  vpc_id             = var.create_vpc ? module.vpc[0].vpc_id : var.vpc_id
  private_subnet_ids = var.create_vpc ? module.vpc[0].private_subnet_ids : var.private_subnet_ids
}
