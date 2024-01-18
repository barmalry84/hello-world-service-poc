module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name                   = local.eks_name
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name            = "node-group-1"
      use_name_prefix = false

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
  }
}

resource "aws_iam_role_policy_attachment" "additional_policy_1" {
  role       = module.eks.eks_managed_node_groups.one.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "additional_policy_2" {
  role       = module.eks.eks_managed_node_groups.one.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AWSWAFFullAccess"
}

resource "aws_iam_role_policy_attachment" "additional_policy_3" {
  role       = module.eks.eks_managed_node_groups.one.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}
