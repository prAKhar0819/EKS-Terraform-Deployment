data "aws_iam_openid_connect_provider" "demo" {
  url = data.aws_eks_cluster.demo.identity[0].oidc[0].issuer

  depends_on = [module.eks]
}


module "alb_controller" {
  source                           = "./modules/alb-controller"
  cluster_name                     = var.cluster_name
  cluster_identity_oidc_issuer     = data.aws_eks_cluster.demo.identity[0].oidc[0].issuer
  cluster_identity_oidc_issuer_arn = data.aws_iam_openid_connect_provider.demo.arn
  aws_region                       = var.region
  vpc_id                           = var.vpc_id
  subnet_ids                       = var.subnet_ids

  depends_on = [ module.eks, module.node ]
}

module "eks" {
  source       = "./modules/eks"
  vpc_id       = var.vpc_id
  subnet_ids   = var.subnet_ids
  cluster_name = var.cluster_name
}

module "node" {
  source       = "./modules/node"
  vpc_id       = var.vpc_id
  subnet_ids   = var.subnet_ids
  cluster_name = var.cluster_name

  depends_on = [ module.eks ]
}



