# EKS Terraform

## 구조

```
eks-terraform/
├── main.tf / variables.tf / outputs.tf / versions.tf / backend.tf / locals.tf
├── environments/
│   ├── dev/ (backend.hcl, terraform.tfvars)
│   └── prd/ (backend.hcl, terraform.tfvars)
└── modules/
    ├── eks-cluster/     # Cluster, IAM Role, SG, 로그, OIDC(IRSA), Access Entry
    ├── eks-node-group/  # Managed Node Group, Launch Template(IMDSv2, gp3 암호화), Node Role
    └── eks-addons/      # vpc-cni, kube-proxy, coredns, pod-identity-agent, ebs-csi
```

## 배포

```bash
ENV=dev
terraform init -backend-config="environments/${ENV}/backend.hcl" -reconfigure
terraform plan  -var-file="environments/${ENV}/terraform.tfvars"
terraform apply -var-file="environments/${ENV}/terraform.tfvars"

# kubeconfig
$(terraform output -raw kubeconfig_command)
```

## 사전 조건

- `terraform.tfvars`의 `vpc_id`, `private_subnet_ids`(2개 AZ 이상)를 실제 값으로 교체
- backend.hcl의 S3 버킷이 존재해야 함
- 프라이빗 서브넷에 인터넷 egress(NAT/TGW)가 없으면 VPC Endpoint 필요:
  `ec2`, `sts`, `eks`, `eks-auth`, `ecr.api`, `ecr.dkr`, `s3`(Gateway), `logs`
- API 엔드포인트는 기본 private 전용 → VPC/온프레미스에서 접근 (`endpoint_private_access_cidrs`)
