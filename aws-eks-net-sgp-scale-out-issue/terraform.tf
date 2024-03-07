## Terraform
terraform {
    backend "s3" {
      bucket         = "ssupp-tfstate"
      key            = "ts-eks-net-sgp-scale-out/terraform.tfstate"
      region         = "ap-northeast-2"
      encrypt        = true
      dynamodb_table = "ssupp-tfstate-lock"
    }
}
