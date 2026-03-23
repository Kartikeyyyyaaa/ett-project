output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Kubernetes API endpoint"
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
  description = "Cluster CA (for kubeconfig)"
}

output "configure_kubectl" {
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
  description = "Command to configure local kubectl"
}
