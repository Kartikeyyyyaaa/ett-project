output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE cluster name"
}

output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "Kubernetes API endpoint"
}

output "configure_kubectl" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
  description = "Command to configure local kubectl"
}
