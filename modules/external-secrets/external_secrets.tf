
# Deploy External Secrets Operator
# Reference: https://aws.amazon.com/blogs/containers/leverage-aws-secrets-stores-from-eks-fargate-with-external-secrets-operator/






# Deploying External Secrets Operator / Controller using Helm 
resource "helm_release" "external_secrets" {

  name       = "external-secrets"
  repository = local.external_secrets_helm_repo
  chart      = local.external_secrets_chart_name
  version    = local.external_secrets_chart_version
  namespace  =   var.k8s_namespace
  create_namespace = true
  atomic     = true
  timeout    = 900
  cleanup_on_fail = true
  set {
      name = "installCRDs"
      value = "true"
      type = "auto"
  }
  set {
      name = "webhook.port"
      value = "9443"
      type = "auto"
  } 

  set {
      name = "clusterName"
      value = var.k8s_cluster_name
      type = "string"
  }
  set {
      name = "region"
      value = local.aws_region_name
      type = "string"
  }
  
  depends_on = [ kubernetes_namespace.external_secrets  ]

}

