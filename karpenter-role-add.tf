# adding karpenter role to service account of karpenter

data "aws_iam_role" "karpenter_role" {
  name = "KarpenterRole-${var.cluster_name}" # Corrected interpolation syntax
  depends_on = [aws_iam_role.karpenter_role]
}

data "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role"
  depends_on = [module.node]
}



resource "kubectl_manifest" "aws_auth_configmap" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${data.aws_iam_role.karpenter_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${data.aws_iam_role.eks_node_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    []
  mapAccounts: |
    []
YAML

  depends_on = [
    aws_iam_role.karpenter_role,  # Ensures IAM role exists
    helm_release.karpenter        # Ensures Karpenter is installed
  ]

}
