# role for nodegroup

resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
})
}

# IAM policy attachment to nodegroup

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-CloudWatchFullAccess" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
} 

resource "aws_iam_role_policy_attachment" "nodes-CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
} 

resource "aws_iam_role_policy_attachment" "nodes-CloudWatchLogsFullAccess" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}



# aws node group creation

resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = var.cluster_name
  node_group_name = "private-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = var.subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = ["t2.medium"]

  scaling_config {
    desired_size = 10
    max_size     = 16
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    node = "kubenode02"
  }



  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.nodes-CloudWatchAgentServerPolicy,
    aws_iam_role_policy_attachment.nodes-CloudWatchFullAccess,
    aws_iam_role_policy_attachment.nodes-CloudWatchLogsFullAccess
    
  ]
}


