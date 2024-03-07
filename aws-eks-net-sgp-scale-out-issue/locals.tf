locals {
  name = "ts-eks-sgp-scale-out"

  region   = "ap-northeast-2"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  vpc_cidr = "10.0.0.0/16"
}
