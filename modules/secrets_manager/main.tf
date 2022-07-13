
# Deploy External Secrets Operator
# Reference: https://aws.amazon.com/blogs/containers/leverage-aws-secrets-stores-from-eks-fargate-with-external-secrets-operator/

locals {
  external_secrets_helm_repo     = "https://charts.external-secrets.io"
  external_secrets_chart_name    = "external-secrets"
  aws_vpc_id                   = data.aws_vpc.selected.id
  aws_region_name              = data.aws_region.current.name
  external_secrets_chart_version = "0.5.8"
  service_account_name         = substr("${var.k8s_cluster_name}-external-secrets",0,64)
}



resource "kubernetes_namespace" "external_secrets" {
  metadata {
    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "external_secrets"
      "app.kubernetes.io/managed-by" = "helm" #"terraform"
      "meta.helm.sh/release-name"   = "external_secrets"
    }
    name = var.k8s_namespace
  }
}


resource "aws_iam_role" "this" {
  name        = local.service_account_name
  description = "Permissions required by the Kubernetes External Secrets to do its job."
  path        = null
  tags = var.aws_tags
  force_detach_policies = true
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role[0].json
}


resource "aws_iam_policy" "this" {
  name        = local.service_account_name
  description = format("Permissions that are required to manage AWS Secrets Manager.")
 
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": "arn:aws:secretsmanager:${local.aws_region_name}:${data.aws_caller_identity.current.account_id}:secret:*"   # It will allow access to all the secrets in the AWS Secrets manager within the region.
        }
      ]
    })

    tags = {
            Name  = "${var.k8s_cluster_name}-secrets-manager-iam"
        }
  }



resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}


# Creating service account and attatching role so that External Secret Pod can access AWS Resources

resource "kubernetes_service_account" "this" {
  automount_service_account_token = true
  metadata {
    name      =  local.service_account_name
    namespace = var.k8s_namespace
    annotations = {
      # This annotation is only used when running on EKS which can
      # use IAM roles for service accounts.
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
      "secretsmanager.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "external_secrets"
      "app.kubernetes.io/managed-by" = "helm" #"terraform"
      "meta.helm.sh/release-name"   = "external_secrets"
      "meta.helm.sh/release-namespace" = var.k8s_namespace
    }
  }
}

resource "kubernetes_cluster_role" "this" {
  metadata {
    name = local.service_account_name

    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "external_secrets"
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
      "services",
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
      "app.kubernetes.io/component"  = "external_secrets"
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
}

# Deploying External Secrets Operator / Controller using Helm 
resource "helm_release" "external_secrets" {

  name       = "external-secrets"
  repository = local.external_secrets_helm_repo
  chart      = local.external_secrets_chart_name
  version    = local.external_secrets_chart_version
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

  depends_on = [ kubernetes_namespace.external_secrets, kubernetes_service_account.this ]
}




# Creating Kubernetes SecretStore in the cluster so that Secrets can synchronise from AWS Secrets Manager
# Once Secrets are synchronised Pods can use the secrets within the cluster


resource "kubectl_manifest" "kubernetes-secret-store" {
    yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: "${var.k8s_cluster_name}-common-secret-store"
  namespace =  ${var.app_namespace}
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${local.aws_region_name}
      auth:
        jwt:
          serviceAccountRef:
            name: ${local.service_account_name}
YAML
}

/*
resource "kubernetes_manifest" "kubernetes-secret-store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
      metadata = {
          name = "${var.k8s_cluster_name}-common-secret-store"
          namespace =  var.app_namespace
      }
      spec = {
          provider = {
            aws = {
              service = "SecretsManager"
              region = local.aws_region_name
              auth = {
                jwt = {
                  serviceAccountRef = {
                    name = local.service_account_name
                  }
                }
              }
            }
          }
      }
  }
}
*/
 
# We will now create our ExternalSecret resource, specifying the secret we want to access and referencing the previously created SecretStore object. 
# We will specify the existing AWS Secrets Manager secret name and keys.


resource "kubectl_manifest" "kubernetes-external-secret" {
    yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: "${var.k8s_cluster_name}-external-secret"
  namespace =  ${var.app_namespace}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: "${var.k8s_cluster_name}-common-secret-store"
    kind: SecretStore
  target:
    name:  "application-credentials"
    creationPolicy: Owner
  data:
  - secretKey:  "application-username"
    remoteRef:
      key: "test/application/credentials" #AWS Secrets Manager secret name
      property:  "app_username" #AWS Secrets Manager secret key
  - secretKey: "application-password"
    remoteRef:
      key: "test/application/credentials" #AWS Secrets Manager secret name
      property: "app_password" #AWS Secrets Manager secret key
YAML
}





/*
resource "kubernetes_manifest" "kubernetes-external-secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
        metadata = {
          name = "${var.k8s_cluster_name}-external-secret"
          namespace =  var.app_namespace
        }
        spec = {
          refreshInterval = "1h"
          secretStoreRef = {
            name = "${var.k8s_cluster_name}-common-secret-store"
            kind = "SecretStore"
          }
          target = {
            name = "application-credentials"
            creationPolicy = "Owner"
          }
          data = {
            - secretKey =  "application-username"
              remoteRef = {
                key = "test/application/credentials" #AWS Secrets Manager secret name
                property =  "app_username" #AWS Secrets Manager secret key
              }
              secretKey = "application-password"
              remoteRef = {
                key = "test/application/credentials" #AWS Secrets Manager secret name
                property = "app_password" #AWS Secrets Manager secret key
              }
          }
        }
  }
}
*/
