# AWS EKS Fargate with AppMesh, External Secret setup with terraform
The Terraform code repo will deploy AWS EKS on Fargate. Managed node groups have not been used in EKS to deploy different pods.
It will also deploy an AWS Load Balancer Controller and a sample game app which will be
exposed externally using an AWS ALB Ingress load balancer.
As all the pods will run on Fargate, a CodeDNS pod patching is required. Kubectl local-exec has been
used in the Terraform code to path CoreDNS.

References used to develop the architecture and code base.

Important Links #

https://gist.github.com/Zheaoli/335bba0ad0e49a214c61cbaaa1b20306
https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html

https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

https://aws.amazon.com/blogs/containers/introducing-aws-load-balancer-controller/


Terraform Ref #

https://jasonwatmore.com/post/2021/05/30/aws-create-a-vpc-with-public-and-private-subnets-and-a-nat-gateway
https://github.com/Prashant-jumpbyte/terraform-aws-vpc-setup/blob/master/modules/networking/main.tf
https://medium.com/appgambit/terraform-aws-vpc-with-private-public-subnets-with-nat-4094ad2ab331


CoreDNS Update for Fargate Profile #

https://github.com/aws/containers-roadmap/issues/944
https://github.com/GSA/datagov-brokerpak-eks/blob/01485f9ec70e109a1e7b17de8efb3f715c9aa7a1/services/terraform/cluster.tf#L77-L145

https://github.com/Prashant-jumpbyte/terraform-aws-vpc-setup/
https://github.com/Harshetjain666/terraform-aws-eks-fargate-cluster



AWS Load Balancer Controller Reference #

https://github.com/stacksimplify/aws-eks-kubernetes-masterclass/tree/master/08-NEW-ELB-Application-LoadBalancers/08-01-Load-Balancer-Controller-Install
https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html

https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/main.tf
https://github.com/DNXLabs/terraform-aws-eks-lb-controller
https://github.com/Young-ook/terraform-aws-eks/blob/1.7.5/modules/lb-controller/main.tf
https://github.com/GSA/terraform-kubernetes-aws-load-balancer-controller


CoreDNS Patching #

https://dev.to/k8sdev/setup-a-fully-private-amazon-eks-on-aws-fargate-cluster-10cb

Kubernetes Tags for ALB #

https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/


