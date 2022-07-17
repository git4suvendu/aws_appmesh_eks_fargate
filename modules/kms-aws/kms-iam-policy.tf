//kms key policy

	data "aws_iam_policy_document" "kms_key_policy" {
	  statement {
	    sid = "EnableAdminAccess"
	
	    principals {
	      type        = "AWS"
	      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
	    }
	
	    actions = [
	      "kms:Create*",
	      "kms:Describe*",
	      "kms:Enable*",
	      "kms:List*",
	      "kms:Put*",
	      "kms:Update*",
	      "kms:Revoke*",
	      "kms:Disable*",
	      "kms:Get*",
	      "kms:Delete*",
	      "kms:ScheduleKeyDeletion",
	      "kms:CancelKeyDeletion",
	      "kms:TagResource",
	      "kms:UntagResource"
	    ]
	
	    resources = ["*"]
	  }
	  statement {
	    sid = "EnableAccessForCloudWatchLogs"
	
	    principals {
	      type = "Service"
	      identifiers = [
	        "cloudwatch.amazonaws.com",
	        "eks.amazonaws.com",
	        "eks-fargate-pods.amazonaws.com",
	        "logs.amazonaws.com"
	      ]
	    }
	
	    actions = [
	      "kms:Encrypt",
	      "kms:Decrypt",
	      "kms:ReEncrypt",
	      "kms:GenerateDataKey",
	      "kms:DescribeKey"
	    ]
	
	    resources = ["*"]
	  }
	}
