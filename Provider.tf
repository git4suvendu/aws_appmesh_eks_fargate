#provider "aws" {
#  region = var.region_name
#  profile = "AWS_741032333307_User"
#}

provider "aws" {
  region     = var.region_name
  default_tags {
   tags = {
     Owner = "Suvendu Mandal"
     Owner_Email       = "suvendu.mandal@accenture.com"
     Owner_Group     = "Accenture UK - AABG"
     Owner_Location     = "UK"
     Environment =  var.environment
     Resource_Region = var.region_name
     EKS_Cluster_Name = "${var.cluster_name}-${var.environment}"
   }
 }
}



terraform {
  backend "s3" {
    bucket = "suvendu-terraform-state" #var.s3_bucket_name
    key    = "eks/test/terraform.tfstate" #var.tfstate_file_path
  #  region = var.region_name
    encrypt= true
  }
}



provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  #config_path = "./.kube/config"
  config_path ="${var.github_runner_base_path}.kube/config"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    #config_path = "./.kube/config"
    config_path ="${var.github_runner_base_path}.kube/config"
  }
}

 