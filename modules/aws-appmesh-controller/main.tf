locals {
  appmesh_controller_helm_repo     = "https://aws.github.io/eks-charts"
  appmesh_controller_chart_name    = "appmesh-controller"
  alb_controller_chart_version = var.aws_appmesh_controller_chart_version
  aws_vpc_id                   = data.aws_vpc.selected.id
  aws_region_name              = data.aws_region.current.name
  service_account_name         = substr("${var.k8s_cluster_name}-appmesh-controller",0,64)
}


resource "kubernetes_namespace" "appmesh_namespace" {
  metadata {
    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "appmesh-controller"
      "app.kubernetes.io/managed-by" = "helm" #"terraform"
      "meta.helm.sh/release-name"   = "appmesh-controller"
    }
    name = var.k8s_namespace
  }
}


resource "aws_iam_role" "this" {
  name        = local.service_account_name
  description = "Permissions required by the Kubernetes AWS Appmesh controller to do its job."
  path        = null
  tags = var.aws_tags
  force_detach_policies = true
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role[0].json
}


resource "aws_iam_policy" "this" {
  name        = local.service_account_name
  description = format("Permissions that are required to manage AWS Appmesh.")
  path        = "/"
  # We use a heredoc for the policy JSON so that we can more easily diff and
  # copy/paste from upstream. Ignore whitespace when you diff to more easily see the changes!
  # Source: `curl -o controller-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json`
  policy = file("${path.module}/aws_appmesh_iam_policy.json")
        tags = {
                 Name        = "${var.k8s_cluster_name}-appmesh-controller-iam"
                }
  }

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "this1" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudMapFullAccess"
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "this2" {
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshFullAccess"
  role       = aws_iam_role.this.name
}

resource "kubernetes_service_account" "this" {
  automount_service_account_token = true
  metadata {
    name      =  local.service_account_name
    namespace = var.k8s_namespace
    annotations = {
      # This annotation is only used when running on EKS which can
      # use IAM roles for service accounts.
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
      "appmesh.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "appmesh-controller"
      "app.kubernetes.io/managed-by" = "helm" #"terraform"
      "meta.helm.sh/release-name"   = "appmesh-controller"
      "meta.helm.sh/release-namespace" = var.k8s_namespace
    }
  }

     depends_on = [ kubernetes_namespace.appmesh_namespace  ]

}

resource "kubernetes_cluster_role" "this" {
  metadata {
    name = local.service_account_name

    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "appmesh-controller"
      "app.kubernetes.io/managed-by" = "helm" #"terraform"
    }
  }

  rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "configmaps",
      "endpoints",
      "events",
      "ingresses",
      "ingresses/status",
      "services",
      "appmesh",
    ]

    verbs = [
      "create",
      "get",
      "list",
      "update",
      "watch",
      "patch",
    ]
  }

  rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "nodes",
      "pods",
      "secrets",
      "services",
      "namespaces",
    ]

    verbs = [
      "get",
      "list",
      "watch",
    ]
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = local.service_account_name

    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "appmesh-controller"
      "app.kubernetes.io/managed-by" = "helm" #"terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.this.metadata[0].name
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata[0].name
    namespace = kubernetes_service_account.this.metadata[0].namespace
  }
  depends_on = [ kubernetes_namespace.appmesh_namespace, kubernetes_service_account.this ]
}

resource "helm_release" "appmesh-controller" {

  name       = "appmesh-controller"
  repository = local.appmesh_controller_helm_repo
  chart      = local.appmesh_controller_chart_name
  version    = local.alb_controller_chart_version
  namespace  = var.k8s_namespace
  create_namespace = false
  atomic     = true
  timeout    = 900
  cleanup_on_fail = true

  set {
      name = "clusterName"
      value = var.k8s_cluster_name
      type = "string"
  }
  set {
      name = "serviceAccount.create"
      value = "false"
      type = "auto"
  }
  set {
      name = "serviceAccount.name"
      value = kubernetes_service_account.this.metadata[0].name
      type = "string"
  }
  set {
      name = "region"
      value = local.aws_region_name
      type = "string"
  }
  set {
      name = "vpcId"
      value = local.aws_vpc_id
      type = "string"
  }
  set {
      name =  "hostNetwork"
      value = var.enable_host_networking
      type = "auto"
  }

  depends_on = [ kubernetes_namespace.appmesh_namespace, kubernetes_service_account.this ]
}


