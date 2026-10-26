# EKS Terraform

## 구조

```
eks-terraform/
├── main.tf / variables.tf / outputs.tf / versions.tf / backend.tf / locals.tf
├── environments/
│   ├── dev/ (backend.hcl, terraform.tfvars)
│   └── prd/ (backend.hcl, terraform.tfvars)
└── modules/
    ├── bastion/         # Public 서브넷 bastion (SSM 접속, kubectl, EKS Access Entry)
    ├── vpc/             # VPC, public/private 서브넷(EKS 태그), IGW, NAT, S3 Gateway Endpoint
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

# bastion 접속 (로컬에 session-manager-plugin 필요) → kubectl 바로 사용 가능
$(terraform output -raw bastion_ssm_command)
```

## 네트워크

`create_vpc = true`(기본)이면 EKS용 VPC를 함께 생성합니다.

| 구분 | CIDR (vpc_cidr=10.0.0.0/16, AZ 2개) | 용도 | 태그 |
|------|------|------|------|
| private | 10.0.0.0/19, 10.0.32.0/19 | Control plane ENI, 노드, Pod | `kubernetes.io/role/internal-elb=1` |
| public  | 10.0.240.0/24, 10.0.241.0/24 | 인터넷 facing LB, NAT | `kubernetes.io/role/elb=1` |

- 모든 서브넷에 `kubernetes.io/cluster/<cluster>=shared` 태그
- private 서브넷 egress는 NAT Gateway (`single_nat_gateway = true` → 1개, false → AZ별 1개)
- S3 Gateway Endpoint로 ECR 레이어 pull 트래픽은 NAT를 거치지 않음
- `vpc_cidr`는 /16 이상, `azs`는 2~4개

기존 VPC를 쓰려면 `create_vpc = false`로 두고 `vpc_id`, `private_subnet_ids`(2개 AZ 이상)를 지정합니다.

## 사전 조건

- backend.hcl의 S3 버킷이 존재해야 함
- 기존 VPC 사용 시, 프라이빗 서브넷에 인터넷 egress(NAT/TGW)가 없으면 VPC Endpoint 필요:
  `ec2`, `sts`, `eks`, `eks-auth`, `ecr.api`, `ecr.dkr`, `s3`(Gateway), `logs`
- API 엔드포인트는 기본 private 전용 → bastion 또는 VPC/온프레미스에서 접근 (`endpoint_private_access_cidrs`)
- bastion은 SSM Session Manager로 접속(inbound 포트 없음). SSH가 필요하면 `bastion_key_name`, `bastion_ssh_allowed_cidrs` 지정
