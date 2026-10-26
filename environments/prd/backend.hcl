# terraform init -backend-config=environments/prd/backend.hcl

bucket       = "wontae-eks-tfstate-386474451889"
key          = "eks/prd/terraform.tfstate"
region       = "ap-northeast-2"
encrypt      = true
use_lockfile = true
