## Terraform
terraform {
    backend "s3" {
      bucket         = "ssupp-tfstate"
      key            = "eks-net-sgp-issue/terraform.tfstate"
      region         = "ap-northeast-2"
      encrypt        = true
      dynamodb_table = "ssupp-tfstate-lock"
    }
}

