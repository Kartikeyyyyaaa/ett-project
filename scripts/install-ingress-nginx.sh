#!/usr/bin/env bash
set -euo pipefail

# Installs ingress-nginx controller (required for Helm Ingress in this project).
# Usage: ./scripts/install-ingress-nginx.sh

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=NodePort \
  --wait

echo "Ingress controller installed. Get address:"
echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller"
