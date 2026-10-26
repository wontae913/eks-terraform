output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id

  # 노드가 NAT 경로 없이 기동되면 클러스터 join 실패 → 라우팅 완료 후 노출
  depends_on = [
    aws_route.private_nat,
    aws_route_table_association.private,
    aws_vpc_endpoint.s3,
  ]
}

output "nat_public_ips" {
  description = "NAT gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}
