data "aws_iam_policy_document" "eks_use_kms_policy" {
	  statement {
	    sid = "EKS_KMS_Usage_Policy"
	
	    actions = [
	      "kms:Encrypt",
	      "kms:Decrypt",
	      "kms:GenerateDataKey",
	      "kms:DescribeKey",
	    ]
	
	    resources = [
	     var.eks_kms_secret_encryption_key_arn,
         var.eks_kms_secret_encryption_alias_arn
	    ]
	  }
	}
