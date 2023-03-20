locals {

  # 创建集群后，请执行以下命令配置kubeconfig
  # aws eks --region <region> update-kubeconfig --name <cluster name>

  #name            = basename(path.cwd)
  region          = data.aws_region.current.name
  cluster_version = "1.25"
  cluster_name    = "37GameEKSCluster"
  # 指定集群IAM role
  cluster_create_iam_role = false
  cluster_iam_role_arn    = "arn:aws:iam::625011733915:role/37GameClusterRole"
  
  #create_cloudwatch_log_group = true
  cluster_log_retention_in_days = 30
  # EKS 会自动创建默认安全组，此次可指定额外多集群安全组
  create_cluster_security_group = false
  cluster_security_group_id = "sg-076208ff8fdb0ca50"
  cluster_additional_security_group_ids = ["sg-0586a955b32e32222"]
  cluster_tags    = {
    "name" = "37GameEKSCluster"
    "org"  = "gaming"
    "Blueprint"  = local.cluster_name
    "GithubRepo" = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_id             = "vpc-0674cdd7208595513"
  #control_plane_subnet_ids = ["subnet-0076276ba39b907d2", "subnet-068c41b2b15cd3dd4", "subnet-0e3fbb88bc117ef90"]
  private_subnet_ids = ["subnet-0076276ba39b907d2", "subnet-068c41b2b15cd3dd4", "subnet-0e3fbb88bc117ef90"]
  # 指定额外的节点组安全组
  create_node_security_group = false
  worker_security_group_ids = ["sg-065466bfdd00ecc99"]
  
  # Prometheus node group
  prom_node_group_prefix = false #直接使用指定的node group name，不添加后缀
  prom_node_group_name = "prom-ng"
  prom_desired_size    = 1 #节点组创建后，在terraform修改此实例数量不起作用，需通过其它途径扩缩节点组
  prom_max_size        = 6
  prom_min_size        = 0
  prom_instance_types  = ["t3.medium"]
  prom_create_iam_role = false #指定节点组IAM role
  prom_iam_role_arn    = "arn:aws:iam::625011733915:role/37GameNodeRole"
  prom_create_launch_template = true # 创建自定义启动模版
  prom_disk_size = 200
  prom_subnet_ids = ["subnet-0076276ba39b907d2", "subnet-068c41b2b15cd3dd4", "subnet-0e3fbb88bc117ef90"]
  prom_k8s_taints = [{key= "app", value="monitoring", "effect"="NO_SCHEDULE"}]
  prom_k8s_labels = {
    environment = "sit"
    app  = "monitoring"
    test = "test"
  }
  prom_additional_tags = {
    app         = "monitoring"
    subnet_type = "private"
  }
  prom_pre_userdata    = <<-EOT
                    #!/bin/bash
                    systemctl -w kernel.pid_max=32768
                EOT

  # Biz node group
  biz_node_group_prefix = false #直接使用指定的node group name，不添加后缀
  biz_node_group_name = "biz-ng"
  biz_desired_size    = 2
  biz_max_size        = 6
  biz_min_size        = 0
  biz_instance_types  = ["t3.medium"]
  biz_create_iam_role = false
  biz_iam_role_arn    = "arn:aws:iam::625011733915:role/37GameNodeRole"
  biz_create_launch_template = true
  biz_disk_size = 100
  biz_subnet_ids = ["subnet-0076276ba39b907d2", "subnet-068c41b2b15cd3dd4", "subnet-0e3fbb88bc117ef90"]
  biz_k8s_taints = [{key= "app", value="biz", "effect"="NO_SCHEDULE"}]
  biz_k8s_labels = {
    environment = "sit"
    app  = "biz"
  }
  biz_additional_tags = {
    app         = "biz"
    subnet_type = "private"
  }
  biz_pre_userdata    = <<-EOT
                    #!/bin/bash
                    systemctl -w kernel.pid_max=32768
                EOT

}
