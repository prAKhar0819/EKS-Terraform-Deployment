output "cluster_name" {
  value = aws_eks_cluster.demo.name
}

output "demo" {
  value = aws_iam_role.demo.arn
}

output "eks_cluster" {
  value = aws_eks_cluster.demo
}
