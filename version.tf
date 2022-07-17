terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.21.0"
    }
    local      = ">= 1.4"
    random     = ">= 2.1"
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.6.0"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

