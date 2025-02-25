# Fetch all subnets in the given VPC
data "aws_subnets" "existing_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Fetch subnet details to check if it's public
data "aws_subnet" "subnet_details" {
  for_each = toset(data.aws_subnets.existing_subnets.ids)
  id       = each.key
}

# Apply required ALB tags to subnets
resource "aws_ec2_tag" "tag_subnets" {
  for_each    = toset(data.aws_subnets.existing_subnets.ids)
  resource_id = each.key
  key         = "kubernetes.io/cluster/${var.cluster_name}"  # Cluster name, NOT ALB controller role
  value       = "owned"
}

# Tag subnets for Karpenter discovery
resource "aws_ec2_tag" "karpenter_tag" {
  for_each    = toset(data.aws_subnets.existing_subnets.ids)
  resource_id = each.key
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# Add public/private specific ALB tags
resource "aws_ec2_tag" "subnet_role_tag" {
  for_each    = toset(data.aws_subnets.existing_subnets.ids)
  resource_id = each.key
  key         = data.aws_subnet.subnet_details[each.key].map_public_ip_on_launch ? "kubernetes.io/role/elb" : "kubernetes.io/role/internal-elb"
  value       = "1"
}


# *********************************************************************************************

# Fetch EKS Managed Node Group Details
data "aws_eks_node_group" "private-nodes" {
  depends_on = [module.eks, module.node]
  cluster_name    = var.cluster_name
  node_group_name = "private-nodes"
}

# Fetch Security Group of the Node Group
data "aws_security_group" "eks_node_sg" {
  depends_on = [module.eks, module.node]
   filter {
    name   = "tag:aws:eks:cluster-name"  # Tag key to search for
    values = [var.cluster_name]          # Make sure var.cluster_name = "demo"
  }
}

# Tag the EKS Managed Node Group Security Group
resource "aws_ec2_tag" "eks_node_sg_tag" {
  depends_on = [module.eks, module.node]
  resource_id = data.aws_security_group.eks_node_sg.id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}
