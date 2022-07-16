
locals {
  external_secrets_helm_repo     = "https://charts.external-secrets.io"
  external_secrets_chart_name    = "external-secrets"
  aws_vpc_id                   = data.aws_vpc.selected.id
  aws_region_name              = data.aws_region.current.name
  external_secrets_chart_version = "0.5.8"
  service_account_name         = substr("${var.k8s_cluster_name}-secret-store",0,64)
}