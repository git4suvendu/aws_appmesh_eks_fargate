
terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}
 


 provider "kubectl" {
  # Configuration options
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  #config_path = "./.kube/config"
  config_path ="${var.github_runner_base_path}.kube/config"
}
 