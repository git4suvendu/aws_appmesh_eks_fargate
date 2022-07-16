

/* =====================
Creating EKS Cluster 
========================*/


resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.cluster_name}-${var.environment}"
   
  role_arn = aws_iam_role.eks_cluster_role.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  version  = var.cluster_version
  
   vpc_config {
    subnet_ids =  concat(var.public_subnets, var.private_subnets)
  }
   
   timeouts {
     delete    =  "30m"
   }
  
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy1,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController1,
    aws_cloudwatch_log_group.cloudwatch_log_group
  ]
}


/* ==================================
Creating IAM Policy for EKS Cluster 
=====================================*/
resource "aws_iam_policy" "AmazonEKSClusterCloudWatchMetricsPolicy" {
  name   = substr("${var.cluster_name}-${var.environment}-AmazonEKSClusterCloudWatchMetricsPolicy",0,64)
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

/* ==================================
Creating IAM Role for EKS Cluster 
=====================================*/

resource "aws_iam_role" "eks_cluster_role" {
  name = substr("${var.cluster_name}-${var.environment}-cluster-role",0,64)
  description = "Allow cluster to manage node groups, fargate nodes and cloudwatch logs"
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

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCloudWatchMetricsPolicy" {
  policy_arn = aws_iam_policy.AmazonEKSClusterCloudWatchMetricsPolicy.arn
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name              = "/aws/eks/${var.cluster_name}-${var.environment}/cluster"
  retention_in_days = 30

  tags = {
    Name        = "${var.cluster_name}-${var.environment}-eks-cloudwatch-log-group"
  }
}


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


/* =======================================
Creating IAM Role for Fargate profile
==========================================*/

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

#==========================================================================================================================

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


################################################################################
# IRSA
# Note - this is different from EKS identity provider
################################################################################

data "tls_certificate" "auth" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = concat([data.tls_certificate.auth.certificates[0].sha1_fingerprint])
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  tags = {  Name  = "${var.cluster_name}-${var.environment}-eks-irsa" }
}

