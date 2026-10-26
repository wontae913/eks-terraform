# terraform init -backend-config=environments/dev/backend.hcl

bucket       = "wontae-eks-tfstate-386474451889"
key          = "eks/dev/terraform.tfstate"
region       = "ap-northeast-2"
encrypt      = true
use_lockfile = true
