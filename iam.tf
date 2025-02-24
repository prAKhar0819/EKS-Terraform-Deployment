# iam role for karpenter

resource "aws_iam_role" "karpenter_role" {
  name = "KarpenterRole-${var.cluster_name}"
  

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.demo.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.demo.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })
}

# Inline policy for EC2, EKS, ECR, and Pricing
resource "aws_iam_role_policy" "karpenter_policy" {
  name = "KarpenterFullAccessPolicy"
  role = aws_iam_role.karpenter_role.name

 policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EC2 permissions for managing instances
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeSubnets",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      # EKS permissions
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      },
      # ECR permissions for pulling images
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      # AWS Pricing API access
      {
        Effect = "Allow"
        Action = [
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      # SSM Managed Instance policy (needed for SSM agent support)
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "*"
      },
      # Full access to Amazon EC2
      {
        Effect = "Allow"
        Action = "ec2:*"
        Resource = "*"
      },
      # EKS Cluster Policy
      {
        Effect = "Allow"
        Action = [
          "eks:ListClusters",
          "eks:DescribeCluster"
        ]
        Resource = "*"
      },
      # Additional Karpenter Permissions
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:ListClusters",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeVpcs",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeImages",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribePolicies",
          "autoscaling:DescribeScheduledActions",
          "autoscaling:DescribeNotificationConfigurations",
          "autoscaling:DescribeLifecycleHooks",
          "iam:GetInstanceProfile",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfiles",
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })

}

# Attach additional managed policies
resource "aws_iam_role_policy_attachment" "karpenter_eks_worker" {
  role       = aws_iam_role.karpenter_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_cni" {
  role       = aws_iam_role.karpenter_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_ecr_readonly" {
  role       = aws_iam_role.karpenter_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_pricing_access" {
  role       = aws_iam_role.karpenter_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSPriceListServiceFullAccess"
}   

resource "aws_iam_role_policy_attachment" "karpenter_CloudWatchFullAccess" {
  role       = aws_iam_role.karpenter_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
} 

resource "aws_iam_role_policy_attachment" "karpenter_CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.karpenter_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
} 

resource "aws_iam_role_policy_attachment" "karpenter_CloudWatchLogsFullAccess" {
  role       = aws_iam_role.karpenter_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
} 

# instance profile

resource "aws_iam_instance_profile" "karpenter_instance_profile" {
  name = "KarpenterInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_role.name
}

# *****************************************************************************************************************************