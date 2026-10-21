locals {
  region_short = {
    "ap-northeast-2" = "an2"
  }[var.region]

  name = "${var.project}-${var.environment}-${local.region_short}"
}
