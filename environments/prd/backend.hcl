# terraform init -backend-config=environments/prd/backend.hcl

bucket       = "hhi-empos-prd-an2-s3-tfstate"
key          = "eks/prd/terraform.tfstate"
region       = "ap-northeast-2"
encrypt      = true
use_lockfile = true
