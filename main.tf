provider "kubernetes" {
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks_blueprints.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}

module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.21.0"

  cluster_name    = local.cluster_name
  create_iam_role = local.cluster_create_iam_role
  iam_role_arn    = local.cluster_iam_role_arn
  
  #create_cloudwatch_log_group = local.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = local.cluster_log_retention_in_days
  #enable_cluster_encryption = false

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id             = local.vpc_id
  #control_plane_subnet_ids = local.control_plane_subnet_ids
  private_subnet_ids = local.private_subnet_ids
  
  create_cluster_security_group = local.create_cluster_security_group
  cluster_security_group_id = local.cluster_security_group_id
  cluster_additional_security_group_ids = local.cluster_additional_security_group_ids

  # EKS CONTROL PLANE VARIABLES
  cluster_version = local.cluster_version
  
  tags = local.cluster_tags
  
  create_node_security_group = local.create_node_security_group
  worker_additional_security_group_ids = local.worker_security_group_ids

  # EKS MANAGED NODE GROUPS
  managed_node_groups = {
    mg_prom = {
      enable_node_group_prefix = local.prom_node_group_prefix
      node_group_name = local.prom_node_group_name
      create_launch_template = local.prom_create_launch_template
      instance_types  = local.prom_instance_types
      desired_size    = local.prom_desired_size
      max_size        = local.prom_max_size
      min_size        = local.prom_min_size
      disk_size       = local.prom_disk_size
      subnet_ids      = local.prom_subnet_ids
      create_iam_role = local.prom_create_iam_role
      iam_role_arn    = local.prom_iam_role_arn
      k8s_taints      = local.prom_k8s_taints
      k8s_labels      = local.prom_k8s_labels
      additional_tags = local.prom_additional_tags
      pre_userdata    = local.prom_pre_userdata
    }
    mg_biz = {
      enable_node_group_prefix = local.biz_node_group_prefix
      node_group_name = local.biz_node_group_name
      create_launch_template = local.biz_create_launch_template
      instance_types  = local.biz_instance_types
      desired_size    = local.biz_desired_size
      max_size        = local.biz_max_size
      disk_size       = local.biz_disk_size
      subnet_ids      = local.biz_subnet_ids
      create_iam_role = local.biz_create_iam_role
      iam_role_arn    = local.biz_iam_role_arn
      #k8s_taints      = local.biz_k8s_taints
      k8s_labels      = local.biz_k8s_labels
      additional_tags = local.biz_additional_tags
      pre_userdata    = local.biz_pre_userdata
    }
  #  mg_2 = {
  #    node_group_name = "mng-2"
  #    instance_types  = local.instance_types
  #    desired_size    = local.desired_size
  #    max_size        = local.max_size
  #    min_size        = local.min_size
  #    subnet_ids      = local.private_subnet_ids
  #    remote_access   = true
  #    ec2_ssh_key     = "defaultJPPEM"
  #  }
  }
  
  # This is the team that manages the EKS cluster provisioning.
  #platform_teams = {
  #  admin = {
  #    users = [
  #      data.aws_caller_identity.current.arn
  #    ]
  #  }
  #}
}

module "kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.21.0/modules/kubernetes-addons"

  eks_cluster_id     = module.eks_blueprints.eks_cluster_id

  #---------------------------------------------------------------
  # ADD-ONS - You can add additional addons here
  # https://aws-ia.github.io/terraform-aws-eks-blueprints/add-ons/
  #---------------------------------------------------------------
  
  enable_aws_load_balancer_controller  = true
  aws_load_balancer_controller_helm_config = {
    name                       = "aws-load-balancer-controller"
    service_account            = "aws-lb-sa"
    chart                      = "aws-load-balancer-controller"
    repository                 = "https://aws.github.io/eks-charts"
    version                    = "1.4.8"
    namespace                  = "kube-system"
    #values = [templatefile("${path.module}/aws-load-balancer-controller/values.yaml", {})]
    #set = [
    #  {
    #    name   = "logLevel"
    #    value  = "debug"
    #  }
    #]
  }
  
  enable_metrics_server = true
  
  enable_kube_prometheus_stack      = true
  kube_prometheus_stack_helm_config = {
    name                      = "kube-prometheus-stack"
    chart                     = "kube-prometheus-stack"
    repository                = "https://prometheus-community.github.io/helm-charts"
    version                   = "43.3.1"
    values = [templatefile("${path.module}/kube_prometheus_stack/values.yaml", {})]
    # 可以通过以下方式获取helm chart的默认values.yaml文件
    # helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    # helm pull prometheus-community/kube-prometheus-stack --version 43.3.1
    # tar -zxvf kube-prometheus-stack-43.3.1.tgz
    # ls -l kube-prometheus-stack/values.yaml
    # 使用EBS卷需要提前安装EBS CSI Driver
    # https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html
    
    #set = [
    #  {
    #    name  = "fullnameOverride"
    #    value = "kube-prometheus-stack"
    #  },
    #  {
    #    name  = "prometheus.prometheusSpec"
    #    value = {}
    #  },
    #  {
    #    name  = "alertmanager.enabled"
    #    value = false
    #  }
    #]
  }
  
  #enable_velero           = true
  #velero_helm_config = {
  #  name        = "velero"
  #  description = "A Helm chart for velero"
  #  chart       = "velero"
  #  version     = "2.30.0"
  #  repository  = "https://vmware-tanzu.github.io/helm-charts/"
  #  namespace   = "velero"
  #  values = [templatefile("${path.module}/velero_values/values.yaml", {
  #    bucket = "velerobackup-wxyan",
  #    region = "ap-northeast-1"
  #  })]
  #}
  
  #enable_karpenter = true
  # Queue optional for native handling of instance termination events
  #karpenter_sqs_queue_arn = "arn:aws:sqs:us-west-2:444455556666:queue1"
  # Optional  karpenter_helm_config
  #karpenter_helm_config = {
  #  name                       = "karpenter"
  #  chart                      = "karpenter"
  #  repository                 = "https://charts.karpenter.sh"
  #  version                    = "0.19.3"
  #  namespace                  = "karpenter"
  #  values = [templatefile("${path.module}/values.yaml", {
  #       eks_cluster_id       = var.eks_cluster_id,
  #       eks_cluster_endpoint = var.eks_cluster_endpoint,
         #service_account      = var.service_account,
  #       operating_system     = "linux"
  #  })]
  #}

  #karpenter_irsa_policies = [] # Optional to add additional policies to IRSA

}