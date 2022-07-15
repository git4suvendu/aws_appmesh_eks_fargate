
# Deploy External Secrets Operator
# Reference: https://aws.amazon.com/blogs/containers/leverage-aws-secrets-stores-from-eks-fargate-with-external-secrets-operator/




 /*
resource "kubernetes_namespace" "external_secrets" {
  metadata {
    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "external_secrets"
      "app.kubernetes.io/managed-by" = "helm" #"terraform"
      "meta.helm.sh/release-name"   = "external_secrets"
    }
    name = "external-secrets" #var.k8s_namespace
  }
}
*/ 


# Deploying External Secrets Operator / Controller using Helm 
resource "helm_release" "external_secrets" {

  name       = "external-secrets"
  repository = local.external_secrets_helm_repo
  chart      = local.external_secrets_chart_name
  version    = local.external_secrets_chart_version
  namespace  = "external-secrets" # var.k8s_namespace
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
  
 # depends_on = [ kubernetes_namespace.external_secrets ]
}

