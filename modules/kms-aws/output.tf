
output "eks_kms_secret_encryption_key_arn" {
  value = aws_kms_key.eks_kms_secret_encryption.arn
}

output "eks_kms_secret_encryption_alias_arn" {
  value = aws_kms_alias.eks_kms_secret_alias.arn
}


output eks_kms_cloudwatch_logs_encryption_key_arn {
  value = aws_kms_key.eks_kms_cloudwatch_logs_encryption.arn
}

output eks_kms_cloudwatch_logs_encryption_alias_arn {
  value = aws_kms_alias.eks_kms_cloudwatch_logs_alias.arn
}