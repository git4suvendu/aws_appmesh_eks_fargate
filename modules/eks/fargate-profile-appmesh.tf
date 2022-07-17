
/* =======================================
Creating Fargate Profile for AppMesh
==========================================*/


#resource "kubernetes_namespace" "appmesh_namespace" {
#  metadata {
#    labels = {
#      "mesh" = "appmesh"
#    }
#    name = "appmesh-system"
#  }
#}

resource "aws_eks_fargate_profile" "eks_appmesh_system" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = substr("${var.cluster_name}-${var.environment}-appmesh-system-profile",0,64)
  pod_execution_role_arn = aws_iam_role.eks_appmesh_system_role.arn
  subnet_ids             = var.private_subnets

  selector {
    namespace = "appmesh-system"
  }
  timeouts {
    create   = "30m"
    delete   = "30m"
  }
}

/* ===========================================
Creating IAM Role for Fargate profile AppMesh
==============================================*/

resource "aws_iam_role" "eks_appmesh_system_role" {
  name = substr("${var.cluster_name}-eks_appmesh_system_role",0,64)
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
           "eks-fargate-pods.amazonaws.com",
           "appmesh.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_appmesh_system_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_appmesh_system_role.name
}


resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_appmesh_system_role.name
}


resource "aws_iam_role_policy_attachment" "AWSCloudMapFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudMapFullAccess"
  role       = aws_iam_role.eks_appmesh_system_role.name
}


resource "aws_iam_role_policy_attachment" "AWSAppMeshFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshFullAccess"
  role       = aws_iam_role.eks_appmesh_system_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy-fluentbit-3" {
  policy_arn = aws_iam_policy.fluentbit_policy.arn
  role       = aws_iam_role.eks_appmesh_system_role.name
}




#==========================================================================================================================
