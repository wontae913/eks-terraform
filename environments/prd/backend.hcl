# terraform init -backend-config=environments/prd/backend.hcl

bucket       = "my-tfstate-bucket" # 본인 S3 버킷으로 교체
key          = "eks/prd/terraform.tfstate"
region       = "ap-northeast-2"
encrypt      = true
use_lockfile = true
