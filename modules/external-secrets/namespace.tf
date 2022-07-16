/*resource "kubernetes_namespace" "external_secrets" {
  metadata {
    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "external_secrets"
      "app.kubernetes.io/managed-by" = "helm" #"terraform"
      "meta.helm.sh/release-name"   = "external_secrets"
    }
    name =  var.k8s_namespace
  }
}
 */

resource "kubernetes_namespace" "application_namespace" {
  metadata {
    labels = {
      "app.kubernetes.io/name"       = "application_namespace"
      "app.kubernetes.io/component"  = "business_application"
      "app.kubernetes.io/managed-by" = "terraform" # "helm" #
    }
    name = var.app_namespace #var.k8s_namespace
  }
}