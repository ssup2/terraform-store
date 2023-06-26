## Terraform
terraform {
    backend "s3" {
      bucket         = "ssupp-tfstate"
      key            = "ts-eks-emr/terraform.tfstate"
      region         = "ap-northeast-2"
      encrypt        = true
      dynamodb_table = "ssupp-tfstate-lock"
    }
}

