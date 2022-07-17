/* ====================================================================
	KMS Key encryption
	=======================================================================*/


   # Generate KMS Master Key for EKS Cluster to encrypt the cluster and secrets

	resource "aws_kms_key" "eks_kms_secret_encryption" {
	  description             = "KMS key used for secret encryption within the EKS cluster"
	  deletion_window_in_days = 14	
	  enable_key_rotation = true
	  policy = data.aws_iam_policy_document.kms_key_policy.json
	}
	
	resource "aws_kms_alias" "eks_kms_secret_alias" {
	  name          = substr("alias/${var.cluster_name}-kms-eks-cluster-${var.environment}",0,64)
	  target_key_id = aws_kms_key.eks_kms_secret_encryption.key_id
	}




   # Generate KMS Master Key for CloudWatch Logs for EKS Cluster

	resource "aws_kms_key" "eks_kms_cloudwatch_logs_encryption" {
	  description             = "EKS KMS key used for CloudWatch Logs"
	  deletion_window_in_days = 14	
	  enable_key_rotation = true	
	  policy = data.aws_iam_policy_document.kms_key_policy.json
	}

	resource "aws_kms_alias" "eks_kms_cloudwatch_logs_alias" {
	  name          = substr("alias/${var.cluster_name}-kms-cloudwatch-${var.environment}",0,64)
	  target_key_id = aws_kms_key.eks_kms_cloudwatch_logs_encryption.key_id
	}
	