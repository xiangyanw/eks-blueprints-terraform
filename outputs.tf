output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.eks_blueprints.configure_kubectl
}

output "platform_teams_configure_kubectl" {
  description = "Configure kubectl for each Platform Team: make sure you're logged in with the correct AWS CLI profile and run the following command to update your kubeconfig"
  value       = try(module.eks_blueprints.teams[0].platform_teams_configure_kubectl["admin"], null)
}