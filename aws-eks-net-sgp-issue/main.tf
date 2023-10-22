## Provider
provider "aws" {
  region = local.region
}

provider "aws" {
  alias  = "ecr"
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  # to avoid issue : https://github.com/hashicorp/terraform-provider-helm/issues/630#issuecomment-996682323
  repository_config_path = "${path.module}/.helm/repositories.yaml" 
  repository_cache       = "${path.module}/.helm"

  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

## Data
data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}

## VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = format("%s-vpc", local.name)

  cidr             = local.vpc_cidr
  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 3, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 3, k + 3)]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true
}

## Security Group
module "security_group_pod" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "security-group-pod"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [ 
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ] 
  egress_with_cidr_blocks = [ 
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ] 
}

## EKS
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name = format("%s-eks", local.name)
  cluster_version = "1.25"

  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_public_access  = true

  eks_managed_node_groups = {
    control = {
      subnet_ids = slice(module.vpc.private_subnets, 0, 1)

      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_types = ["m5.large"]
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        type = "control"
      }

      taints = {
        dedicated = {
          key    = "type"
          value  = "control"
          effect = "NO_SCHEDULE"
        }
      }
    }

    app = {
      subnet_ids = slice(module.vpc.private_subnets, 0, 1)

      min_size     = 2
      max_size     = 2
      desired_size = 2

      instance_types = ["m5.large"]
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        type = "app"
      }
    }
  }

  ## Node Security Group
  node_security_group_additional_rules = {
    ingress_self_all = {
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
    }
    egress_all = {
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  }

  manage_aws_auth_configmap = true
}

## EKS / Addons
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        nodeSelector: {
          type: "control"
        }
        tolerations: [
          {
            key: "type",
            value: "control",
            operator: "Equal",
            effect: "NoSchedule"
          }
        ]
      })
    }
    vpc-cni = {
      addon_version = "v1.12.2-eksbuild.1"
      configuration_values = jsonencode({
        env: {
          ENABLE_POD_ENI: "true",
          WARM_ENI_TARGET: "0"
        }
      })
    }
    kube-proxy = {
      most_recent = true
    }
  }
}

## EKS / Security Group Policy
resource "kubectl_manifest" "security_group_policy" {
  yaml_body = <<-YAML
    apiVersion: vpcresources.k8s.aws/v1beta1
    kind: SecurityGroupPolicy
    metadata:
      name: curl
      namespace: default
    spec:
      podSelector: 
        matchLabels:
          role: curl
      securityGroups:
        groupIds:
        - ${module.security_group_pod.security_group_id}
  YAML
}

