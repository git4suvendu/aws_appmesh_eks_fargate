
/* ====================================================================
Creating Fargate Profile for External Secrets
=======================================================================*/

resource "aws_eks_fargate_profile" "eks_fargate_external_secrets" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = substr("${var.cluster_name}-${var.environment}-extsecrets-fargate-profile",0,64)
  pod_execution_role_arn = aws_iam_role.eks_fargate_extsecrets_role.arn
  subnet_ids             = var.private_subnets

  selector {
    namespace = "external-secrets"
  }
  timeouts {
    create   = "30m"
    delete   = "30m"
  }
}

/* ==================================================================
Creating Fargate Profile Roles for External Secrets
========================================================================*/

resource "aws_iam_role" "eks_fargate_extsecrets_role" {
  name = substr("${var.cluster_name}-eks_fargate_extsecrets_role",0,64)
  description = "Allow fargate cluster to allocate resources for running pods - External Secrets"
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
           "eks-fargate-pods.amazonaws.com",
           "secretsmanager.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy4" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_extsecrets_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy4" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_fargate_extsecrets_role.name
}


resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController4" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_fargate_extsecrets_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy-fluentbit-4" {
  policy_arn = aws_iam_policy.fluentbit_policy.arn
  role       = aws_iam_role.eks_fargate_extsecrets_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy-Secrets-Manager" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.eks_fargate_extsecrets_role.name
}

