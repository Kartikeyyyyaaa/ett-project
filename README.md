# DevOps Demo — Microservices on Kubernetes

Production-style portfolio project: **React** frontend, **Node.js** REST API, **PostgreSQL** database, packaged with **Docker**, deployed via **Helm** to **Kubernetes**, with **Ingress**, **HPA**, **CI/CD** (GitHub Actions), optional **Terraform** (EKS / GKE), **Prometheus & Grafana**, and **EFK** logging (Elasticsearch, Fluentd, Kibana).

---

## Architecture (high level)

```
                         ┌─────────────────────────────────────────┐
                         │              Ingress (nginx)            │
                         │   host: devops-demo.local               │
                         └───────────────┬─────────────────────────┘
                                         │
                    ┌────────────────────┴────────────────────┐
                    │                                         │
                    ▼                                         ▼
           ┌────────────────┐                        ┌────────────────┐
           │   Frontend     │                        │    Backend     │
           │  Deployment    │                        │  Deployment    │
           │  (nginx+SPA)   │                        │  Node/Express  │
           │  + HPA         │                        │  + HPA         │
           └───────┬────────┘                        └───────┬────────┘
                   │                                         │
                   │  Static assets                          │  SQL
                   │                                         ▼
                   │                                ┌────────────────┐
                   │                                │  PostgreSQL    │
                   │                                │  StatefulSet   │
                   │                                └────────────────┘
                   │
     Browser calls  │  /  → frontend service
     /api/*         └── (Ingress) → backend service → DB

Observability (install separately):
  Prometheus/Grafana (kube-prometheus-stack) — metrics & dashboards
  EFK in namespace `logging` — cluster logs → Elasticsearch → Kibana
```

**Traffic flow**

1. **Ingress** routes `/api` to the backend `Service`, `/` to the frontend `Service`.
2. **Frontend** is a React SPA built with Vite; in-cluster it uses same-origin `/api` (no CORS issues).
3. **Backend** reads DB connection from **ConfigMap** + **Secret** (non-sensitive vs sensitive).
4. **HPA** scales frontend and backend Deployments on CPU.
5. **PostgreSQL** runs as a **StatefulSet** with a PVC.

---

## Repository layout

```
ett/
├── README.md                      # This file
├── docker-compose.yml             # Local stack without Kubernetes
├── app/
│   ├── backend/                   # Node.js Express API + Dockerfile
│   └── frontend/                  # React (Vite) UI + Dockerfile
├── helm/devops-demo/              # Helm chart (Deployments, Services, CM, Secret, Ingress, HPA)
├── .github/workflows/ci-cd.yml   # Build → Docker Hub → Helm upgrade
├── jenkins/Jenkinsfile            # Optional Jenkins pipeline (same idea as CI)
├── terraform/
│   ├── aws-eks/                   # EKS + VPC (terraform-aws-modules)
│   ├── gke/                       # Minimal GKE cluster
│   └── minikube/                  # Notes for local Minikube
├── monitoring/
│   └── values-kube-prometheus-stack.yaml   # Prometheus & Grafana Helm values
├── logging/efk/                   # Elasticsearch, Kibana, Fluentd (namespace `logging`)
└── scripts/
    └── install-ingress-nginx.sh   # Optional ingress-nginx install via Helm
```

---

## Components (what each part does)

| Component | Role |
|-----------|------|
| **Frontend** | React UI; nginx serves `dist/`; API calls use `/api` via Ingress. |
| **Backend** | Express REST API; connects to PostgreSQL; `/api/health`, `/api/ready`, `/api/users`. |
| **PostgreSQL** | Primary data store; credentials via Kubernetes **Secret**. |
| **Helm chart** | Packages Deployments, Services, ConfigMap, Secret, Ingress, HPA, optional ServiceMonitor. |
| **Ingress** | HTTP routing and TLS hook (e.g. cert-manager) at the edge. |
| **HPA** | Autoscales pods based on CPU (requires metrics-server). |
| **GitHub Actions** | Builds images, pushes to Docker Hub, runs `helm upgrade` with new tags. |
| **Terraform (AWS)** | VPC + EKS managed node group for a realistic cloud baseline. |
| **Terraform (GCP)** | Minimal zonal GKE cluster + node pool. |
| **kube-prometheus-stack** | Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics. |
| **EFK** | Fluentd DaemonSet ships container logs to Elasticsearch; Kibana for search/UI. |

---

## API reference (backend)

Base URL in-cluster via Ingress: `http://<ingress-host>/api`  
Local compose: `http://localhost:3000/api`

| Method | Path | Description |
|--------|------|----------------|
| GET | `/api/health` | Liveness-style JSON (`status`, `service`, `timestamp`). |
| GET | `/api/ready` | Readiness; returns 200 when DB is reachable, 503 otherwise. |
| GET | `/api/users` | List users (`id`, `name`, `email`, `created_at`). |
| POST | `/api/users` | Body: `{"name":"...","email":"..."}` — creates user. |
| GET | `/metrics` | Plain text placeholder (wire to `prom-client` for full Prometheus metrics). |

### Example `curl` commands

```bash
# Health (through Ingress — replace host and port as needed)
curl -sS http://devops-demo.local/api/health

# Readiness
curl -sS -o /dev/null -w "%{http_code}\n" http://devops-demo.local/api/ready

# List users
curl -sS http://devops-demo.local/api/users | jq .

# Create user
curl -sS -X POST http://devops-demo.local/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Ada Lovelace","email":"ada@example.com"}'
```

**Postman**: create a collection with base URL `http://devops-demo.local` (or your Ingress URL) and requests `GET /api/health`, `GET /api/users`, `POST /api/users` with JSON body as above.

---

## Prerequisites

- Docker (for local compose / image builds)
- kubectl, Helm 3
- A Kubernetes cluster: **Minikube**, **kind**, **EKS**, **GKE**, etc.
- For cloud Terraform: AWS CLI / GCP SDK and credentials
- For CI: Docker Hub account; GitHub repository secrets (see below)

---

## Step-by-step: local Docker Compose (fastest)

```bash
cd ett
docker compose up --build
```

- UI: [http://localhost:8080](http://localhost:8080)  
- API directly: [http://localhost:3000/api/health](http://localhost:3000/api/health)  
(Frontend is built with `VITE_API_BASE_URL=http://localhost:3000` so the browser can reach the API.)

---

## Step-by-step: Minikube

1. **Start cluster** (see `terraform/minikube/README.md`):

   ```bash
   minikube start --cpus=4 --memory=8192 --driver=docker
   minikube addons enable ingress
   ```

2. **Metrics for HPA**:

   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   # If needed on Minikube:
   kubectl patch deployment metrics-server -n kube-system --type='json' \
     -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
   ```

3. **Build and load images** (example — replace `YOUR_USER`):

   ```bash
   export DOCKERHUB_USER=yourdockerhub
   docker build -t $DOCKERHUB_USER/devops-demo-backend:latest app/backend
   docker build -t $DOCKERHUB_USER/devops-demo-frontend:latest --build-arg VITE_API_BASE_URL= app/frontend
   minikube image load $DOCKERHUB_USER/devops-demo-backend:latest
   minikube image load $DOCKERHUB_USER/devops-demo-frontend:latest
   ```

4. **Install chart** (copy `helm/devops-demo/values-minikube.yaml` to `values-local.yaml` and set repositories):

   ```bash
   helm upgrade --install devops-demo ./helm/devops-demo \
     -f helm/devops-demo/values-minikube.yaml \
     --set frontend.image.repository=$DOCKERHUB_USER/devops-demo-frontend \
     --set backend.image.repository=$DOCKERHUB_USER/devops-demo-backend \
     --set frontend.image.tag=latest \
     --set backend.image.tag=latest \
     --wait
   ```

5. **Hosts file** — get Minikube IP and map the Ingress host:

   ```bash
   minikube ip
   # /etc/hosts  →  <minikube-ip> devops-demo.local
   ```

6. Open `http://devops-demo.local/` and run the `curl` examples against the same host.

---

## Step-by-step: AWS EKS (Terraform)

```bash
cd terraform/aws-eks
cp terraform.tfvars.example terraform.tfvars   # edit region, names, tags
terraform init
terraform apply
aws eks update-kubeconfig --region us-east-1 --name devops-demo-eks
```

Then install **ingress-nginx** (if not using a cloud LB integration you prefer):

```bash
chmod +x ../../scripts/install-ingress-nginx.sh
../../scripts/install-ingress-nginx.sh
```

Push images to Docker Hub (from repo root):

```bash
docker build -t YOUR_USER/devops-demo-backend:latest app/backend
docker build -t YOUR_USER/devops-demo-frontend:latest --build-arg VITE_API_BASE_URL= app/frontend
docker push YOUR_USER/devops-demo-backend:latest
docker push YOUR_USER/devops-demo-frontend:latest
```

Deploy:

```bash
helm upgrade --install devops-demo ./helm/devops-demo \
  --set frontend.image.repository=YOUR_USER/devops-demo-frontend \
  --set backend.image.repository=YOUR_USER/devops-demo-backend \
  --set secrets.postgresPassword='choose-a-strong-password' \
  --wait
```

Point DNS or `/etc/hosts` to the Ingress controller load balancer hostname.

---

## Step-by-step: GKE (Terraform)

```bash
cd terraform/gke
terraform init
terraform apply -var="project_id=YOUR_GCP_PROJECT"
gcloud container clusters get-credentials devops-demo-gke --region us-central1 --project YOUR_GCP_PROJECT
```

Then install ingress controller and Helm chart as for EKS.

---

## CI/CD — GitHub Actions

Workflow: `.github/workflows/ci-cd.yml`

**Secrets (repository)**

| Secret | Purpose |
|--------|---------|
| `DOCKERHUB_USERNAME` | Docker Hub user |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `KUBE_CONFIG` | **Base64-encoded** kubeconfig for the target cluster (`base64 -w0 ~/.kube/config`) |

**Optional GitHub Variables**

| Variable | Purpose |
|----------|---------|
| `K8S_NAMESPACE` | Namespace for Helm (default `default`) |
| `HELM_RELEASE_NAME` | Helm release name (default `devops-demo`) |

On each push to `main`, the workflow builds and pushes `devops-demo-backend` and `devops-demo-frontend` with tag = first 12 chars of `GITHUB_SHA`, then runs `helm upgrade --install` with those tags.

---

## Monitoring — Prometheus & Grafana

Install [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f monitoring/values-kube-prometheus-stack.yaml
```

Port-forward Grafana (default admin password in values file — **change in production**):

```bash
kubectl port-forward -n monitoring svc/kube-prom-grafana 3000:80
```

Optional: enable a **ServiceMonitor** for the backend after Prometheus Operator is installed:

```bash
helm upgrade devops-demo ./helm/devops-demo --set monitoring.serviceMonitor.enabled=true
```

---

## Logging — EFK

Apply in order (ConfigMap before StatefulSet):

```bash
kubectl apply -f logging/efk/namespace.yaml
kubectl apply -f logging/efk/elasticsearch-configmap.yaml
kubectl apply -f logging/efk/elasticsearch.yaml
kubectl apply -f logging/efk/kibana.yaml
kubectl apply -f logging/efk/fluentd-rbac.yaml
kubectl apply -f logging/efk/fluentd-daemonset.yaml
```

**Notes**

- Elasticsearch is **resource-heavy**; ensure nodes have enough RAM (often **≥4 GiB** free for the pod). On Linux hosts, `vm.max_map_count` may need raising (see Elastic docs).
- Fluentd expects log paths under `/var/log` and `/var/lib/docker/containers` on nodes (typical for Docker/containerd-based clusters).

Port-forward Kibana:

```bash
kubectl port-forward -n logging svc/kibana 5601:5601
```

---

## Helm chart — notable values

- `frontend.*` / `backend.*` — images, replicas, resources, HPA.
- `config.*` — database name, user, port (ConfigMap).
- `secrets.postgresPassword` / `secrets.dbPassword` — **Secret** data (do not commit real passwords).
- `ingress.*` — host rules, TLS, annotations.
- `monitoring.serviceMonitor.enabled` — requires Prometheus Operator CRDs.

---

## Security notes (portfolio / prod checklist)

- Replace default passwords; use **Sealed Secrets**, **External Secrets**, or cloud secret managers.
- Restrict Ingress and API exposure; use TLS (`cert-manager`).
- Scan images in CI (Trivy, etc.) — not included here but recommended.
- Lock Terraform state (S3 + DynamoDB on AWS).

---

## License

MIT — use freely for learning and portfolio work.
