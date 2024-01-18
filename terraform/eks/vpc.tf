module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  version                = "v5.5.1"
  name                   = local.name
  cidr                   = var.cidr_base
  azs                    = local.azs
  private_subnets        = var.private_subnets
  public_subnets         = var.public_subnets
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true

  private_subnet_tags = { "kubernetes.io/role/internal-elb" : "1" }
  public_subnet_tags  = { "kubernetes.io/role/elb" : "1" }
}