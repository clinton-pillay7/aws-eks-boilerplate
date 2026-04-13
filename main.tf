# main.tf

provider "aws" {
  region = "af-south-1" # Your local region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "flask-eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["af-south-1a", "af-south-1b", "af-south-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Cost-saving for dev/test
  
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "flask-crud-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  # 1. Enable the modern Access Entry API
  authentication_mode = "API_AND_CONFIG_MAP"

  # 2. Automatically give the creator (you) admin rights
  enable_cluster_creator_admin_permissions = true

  node_security_group_additional_rules = {
    ingress_allow_all_http = {
      description      = "Allow HTTP from anywhere"
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress_allow_flask_port = {
      description      = "Allow Flask container port"
      protocol         = "tcp"
      from_port        = 5000
      to_port          = 5000
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  }
  eks_managed_node_groups = {
    flask_nodes = {
      instance_types = ["t3.small"]
      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}

