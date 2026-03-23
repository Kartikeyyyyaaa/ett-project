variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "cluster_name" {
  type    = string
  default = "devops-demo-gke"
}

variable "node_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "node_count" {
  type    = number
  default = 2
}
