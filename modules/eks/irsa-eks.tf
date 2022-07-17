
################################################################################
# IRSA
# Note - this is different from EKS identity provider
################################################################################

data "tls_certificate" "auth" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = concat([data.tls_certificate.auth.certificates[0].sha1_fingerprint])
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  tags = {  Name  = "${var.cluster_name}-${var.environment}-eks-irsa" }
}
