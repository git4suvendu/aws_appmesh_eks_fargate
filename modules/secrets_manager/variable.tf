variable "k8s_cluster_type" {
  default = "eks"
}

variable "k8s_cluster_name" {
  description = "Name of the Kubernetes cluster. This string is used to contruct the AWS IAM permissions and roles. If targeting EKS, the corresponsing managed cluster name must match as well."
  type        = string
}
 
 variable "k8s_namespace" {
  description = "Kubernetes namespace to deploy the External Secrets"
  type        = string
  default     = "default"
}

variable "aws_vpc_id" {
  description = "ID of the Virtual Private Network to utilize. Can be ommited if targeting EKS."
  type        = string
  default     = null
}

variable "aws_region_name" {
  description = "ID of the Virtual Private Network to utilize. Can be ommited if targeting EKS."
  type        = string
  default     = null
}

variable "aws_tags" {
  description = "Common AWS tags to be applied to all AWS objects being created."
  type        = map(string)
  default     = {}
}

 

variable "enable_host_networking" {
  description = "If true enable host networking."
  type        = bool
  default     = false
}

variable "chart_env_overrides" {
  description = "env values passed to the External Secrets helm chart."
  type        = map(any)
  default     = {}
}

variable "service_account_name" {
  description = "Service Account Name of the External Secrets - Secrets Manager"
  type        = string
  default     = "external-secrets"
}

variable "app_namespace" {
   description      =   "Kubernetes namespace name in which the business application is deployed "
   type = string
   default = null
}