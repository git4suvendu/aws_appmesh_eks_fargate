
data "aws_vpc" "selected" {
  id = var.k8s_cluster_type == "eks" ? data.aws_eks_cluster.selected[0].vpc_config[0].vpc_id : var.aws_vpc_id
}

data "aws_region" "current" {
  name = var.aws_region_name
}

data "aws_caller_identity" "current" {}


# The EKS cluster (if any) that represents the installation target.
data "aws_eks_cluster" "selected" {
  count      = var.k8s_cluster_type == "eks" ? 1 : 0
  name       = var.k8s_cluster_name
}

# Authentication data for that cluster
data "aws_eks_cluster_auth" "selected" {
  count      = var.k8s_cluster_type == "eks" ? 1 : 0
  name       = var.k8s_cluster_name
}


data "aws_iam_policy_document" "eks_oidc_assume_role" {
  count = var.k8s_cluster_type == "eks" ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.selected[0].identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${var.k8s_namespace}:${local.service_account_name}"
      ]
    }
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.selected[0].identity[0].oidc[0].issuer, "https://", "")}"
      ]
      type = "Federated"
    }
  }
}