
/* =======================================
Creating Fargate Profile for Applications
==========================================*/

resource "aws_eks_fargate_profile" "eks_fargate_app" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = substr("${var.cluster_name}-${var.environment}-app-fargate-profile",0,64)
  pod_execution_role_arn = aws_iam_role.eks_fargate_app_role.arn
  subnet_ids             = var.private_subnets

  dynamic "selector" {
    for_each = var.fargate_app_namespace
    content {
        namespace = selector.value
    }
  }
  timeouts {
    create   = "30m"
    delete   = "30m"
  }
}


resource "aws_iam_policy" "fluentbit_policy" {
  name        = substr("${var.cluster_name}-${var.environment}-fluentbi-cloudwatch",0,64)
  description = format("Permissions that are required to send FluentBit logs to CloudWatch.")
  # Source: `curl -o permissions.json  https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json`
  policy = file("${path.module}/fluentbit-cloudwatch-policy.json")
        tags = {
                 Name        = substr("${var.cluster_name}-${var.environment}-fluentbi-cloudwatch-iam",0,64)
                }
  }


/* =======================================================
Creating IAM Role for Fargate profile Appliction
==============================================================*/

resource "aws_iam_role" "eks_fargate_app_role" {
  name = "${var.cluster_name}-fargate_cluster_app_role"
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

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_app_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_fargate_app_role.name
}


resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_fargate_app_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy-fluentbit-1" {
  policy_arn = aws_iam_policy.fluentbit_policy.arn
  role       = aws_iam_role.eks_fargate_app_role.name
}
