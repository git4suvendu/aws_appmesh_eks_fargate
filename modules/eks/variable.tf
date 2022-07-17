variable "cluster_name" {
  description = "the name of your stack, e.g. \"demo\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
}


variable "private_subnets" {
  description = "List of private subnet IDs"
}

variable "public_subnets" {
  description = "List of private subnet IDs"
}

variable "fargate_app_namespace" {
  description = "Name of fargate selector namespace"
}


variable "cluster_version" {
  description = "Version of the EKS Cluster"
  default = "1.22"
}



variable "eks_kms_secret_encryption_key_arn" {
	    description = "kms key id/arn for eks"
	}

variable "eks_kms_secret_encryption_alias_arn" {
	    description = "kms key (alias) arn for eks"
	}

 
 variable "eks_kms_cloudwatch_logs_encryption_key_arn" {
	    description = "kms key id/arn for CloudWatch"
	}

variable "eks_kms_cloudwatch_logs_encryption_alias_arn" {
	    description = "kms key (alias) arn for CloudWatch"
	}
 