#!/usr/bin/env bash
#
# Rebuilds the repo into exactly 10 commits (topic-based).
# Run from anywhere:  bash /Users/kartikeya/ett/scripts/make-10-commits.sh
#
# What it does:
#   1) Creates orphan branch "ten-commits-rebuild" (keeps all files on disk)
#   2) Unstages everything, then commits in order (backend → frontend → dockerfiles → …)
#   3) Renames branch to "main" and optionally force-pushes to origin
#
# Prerequisites:
#   - Commit 1 includes .gitignore first so node_modules/ and dist/ are never tracked.
#   - Backend/frontend Dockerfiles are committed in commit 3 only (split from commits 1–2).
#
set -euo pipefail

ROOT="${1:-/Users/kartikeya/ett}"
cd "$ROOT"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository: $ROOT"
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Warning: working tree is not clean. Commit or stash changes first."
  echo "Run: git status"
  exit 1
fi

echo ">>> Creating orphan branch (your old main is still in reflog)"
git checkout --orphan ten-commits-rebuild
git rm -rf --cached . 2>/dev/null || true

# --- Commit 1: backend (no Dockerfiles yet) + .gitignore ---
git add .gitignore
git add app/backend/
git reset HEAD app/backend/Dockerfile app/backend/.dockerignore 2>/dev/null || true
git commit -m "feat(backend): add Express REST API with PostgreSQL client"

# --- Commit 2: frontend (no Dockerfiles yet) ---
git add app/frontend/
git reset HEAD app/frontend/Dockerfile app/frontend/.dockerignore 2>/dev/null || true
git commit -m "feat(frontend): add React UI with Vite and nginx config"

# --- Commit 3: Dockerfiles ---
git add app/backend/Dockerfile app/backend/.dockerignore app/frontend/Dockerfile app/frontend/.dockerignore
git commit -m "chore(docker): add production Dockerfiles for backend and frontend"

# --- Commit 4: docker-compose ---
git add docker-compose.yml
git commit -m "chore(compose): add docker-compose for local Postgres, API, and UI"

# --- Commit 5: Helm ---
git add helm/devops-demo/
git commit -m "feat(k8s): add Helm chart with Deployments, Services, Ingress, HPA, ConfigMaps and Secrets"

# --- Commit 6: GitHub Actions ---
git add .github/workflows/ci-cd.yml
git commit -m "ci: add GitHub Actions to build, push images and deploy with Helm"

# --- Commit 7: Terraform ---
git add terraform/
git commit -m "infra: add Terraform for EKS and GKE and Minikube notes"

# --- Commit 8: Monitoring ---
git add monitoring/
git commit -m "feat(observability): add kube-prometheus-stack Helm values"

# --- Commit 9: EFK ---
git add logging/
git commit -m "feat(logging): add EFK manifests for Elasticsearch, Fluentd, and Kibana"

# --- Commit 10: docs, Jenkins, scripts ---
chmod +x scripts/install-ingress-nginx.sh 2>/dev/null || true
git add README.md jenkins/ scripts/
git commit -m "docs: add README, Jenkinsfile, and helper scripts"

echo ""
echo ">>> Done. New history is on branch: ten-commits-rebuild"
echo ""
echo "Next steps (pick ONE):"
echo ""
echo "A) Replace main locally and force-push to GitHub (rewrites remote history):"
echo "   git branch -M ten-commits-rebuild main"
echo "   git push --force-with-lease origin main"
echo ""
echo "B) Keep old main, push new branch for a PR:"
echo "   git push -u origin ten-commits-rebuild"
echo ""
