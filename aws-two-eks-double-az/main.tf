## Provider
provider "aws" {
  region = local.region
}

provider "kubernetes" {
  alias = "one"

  host                   = module.one_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.one_eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.one_eks.cluster_name]
  }
}

provider "kubernetes" {
  alias = "two"

  host                   = module.two_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.two_eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.two_eks.cluster_name]
  }
}

## Data
data "aws_availability_zones" "available" {}

## Local Vars
locals {
  name = "ts-two-eks-double-az"

  region   = "ap-northeast-2"
  azs      = slice(data.aws_availability_zones.available.names, 0, 4)
  vpc_cidr = "10.0.0.0/16"
}

## VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = format("%s-vpc", local.name)

  cidr             = local.vpc_cidr
  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 10)]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 # for AWS Load Balancer Controller
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1                            # for AWS Load Balancer Controller
    "karpenter.sh/discovery"          = format("%s-eks", local.name) # for Karpenter
  }
}

## EKS One
module "one_eks" {
  providers = {
    kubernetes = kubernetes.one
  }
  source = "terraform-aws-modules/eks/aws"

  cluster_name = format("%s-one-eks", local.name)

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    zonea = {
      min_size     = 5
      max_size     = 5
      desired_size = 5

      instance_types = ["t3.small"]
      subnet_ids = [module.vpc.private_subnets[0]]
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        zone = "a"
      }
    }

    zoneb = {
      min_size     = 5
      max_size     = 5
      desired_size = 5

      instance_types = ["t3.small"]
      subnet_ids = [module.vpc.private_subnets[1]]
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        zone = "b"
      }
    }
  }

  ## Node Security Group
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }
}

## EKS Two
module "two_eks" {
  providers = {
    kubernetes = kubernetes.two
  }
  source = "terraform-aws-modules/eks/aws"

  cluster_name = format("%s-two-eks", local.name)

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    zonec = {
      min_size     = 5 
      max_size     = 5
      desired_size = 5

      instance_types = ["t3.small"]
      subnet_ids = [module.vpc.private_subnets[2]]
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        zone = "c"
      }
    }

    zoned = {
      min_size     = 5
      max_size     = 5
      desired_size = 5

      instance_types = ["t3.small"]
      subnet_ids = [module.vpc.private_subnets[3]]
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        zone = "d"
      }
    }
  }

  ## Node Security Group
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }
}

