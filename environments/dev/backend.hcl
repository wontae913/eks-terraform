# terraform init -backend-config=environments/dev/backend.hcl

bucket       = "hhi-empos-dev-an2-s3-tfstate"
key          = "eks/dev/terraform.tfstate"
region       = "ap-northeast-2"
encrypt      = true
use_lockfile = true
