# GKE (Terraform)

Minimal zonal cluster suitable for demos. Set `project_id` and optionally `region` / machine types.

```bash
terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID"
gcloud container clusters get-credentials devops-demo-gke --region us-central1 --project YOUR_PROJECT_ID
```

For production workloads, use private clusters, workload identity, and node auto-provisioning as appropriate.
