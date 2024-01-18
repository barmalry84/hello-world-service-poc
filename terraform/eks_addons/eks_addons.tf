locals {
  eks_name        = "qa-eks-test"
  node_group_name = "node-group-1"
}

data "aws_eks_node_group" "group" {
  cluster_name    = local.eks_name
  node_group_name = "node-group-1"
}

data "aws_eks_cluster" "eks" {
  name = local.eks_name
}

data "aws_eks_cluster_auth" "eks" {
  name = local.eks_name
}

module "eks_monitoring_logging" {

  source = "shamimice03/eks-monitoring-logging/aws"

  cluster_name = local.eks_name
  aws_region   = "eu-west-1"
  namespace    = "amazon-cloudwatch"

  enable_cwagent    = true
  enable_fluent_bit = true

  nodegroup_roles = [
    split("/", data.aws_eks_node_group.group.node_role_arn)[1]
  ]
}

resource "null_resource" "adding_additional_things" {
  provisioner "local-exec" {
    command = <<EOT
#!/bin/bash

aws eks --region eu-west-1 update-kubeconfig --name ${local.eks_name}
helm repo add eks https://aws.github.io/eks-charts || exit 0
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=${local.eks_name} || exit 0
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || exit 0
helm repo add grafana https://grafana.github.io/helm-charts || exit 0
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
helm install grafana grafana/grafana --namespace monitoring
EOT
  }
}