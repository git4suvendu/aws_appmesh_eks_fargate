
/* ====================================================================
Creating Fargate Profile for EKS System Components (e.g. CoreDNS)
=======================================================================*/

resource "aws_eks_fargate_profile" "eks_fargate_system" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = substr("${var.cluster_name}-${var.environment}-system-fargate-profile",0,64)
  pod_execution_role_arn = aws_iam_role.eks_fargate_system_role.arn
  subnet_ids             = var.private_subnets

  selector {
    namespace = "kube-system"
  }
  selector {
    namespace = "default"
  }
  timeouts {
    create   = "30m"
    delete   = "30m"
  }
}

/* ==================================================================
Creating Fargate Profile for EKS System Components (e.g. CoreDNS)
========================================================================*/

resource "aws_iam_role" "eks_fargate_system_role" {
  name = substr("${var.cluster_name}-eks_fargate_system_role",0,64)
  description = "Allow fargate cluster to allocate resources for running pods"
  force_detach_policies = true
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [ 
           "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_system_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_fargate_system_role.name
}


resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_fargate_system_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy-fluentbit-2" {
  policy_arn = aws_iam_policy.fluentbit_policy.arn
  role       = aws_iam_role.eks_fargate_system_role.name
}

#==========================================================================================================================
