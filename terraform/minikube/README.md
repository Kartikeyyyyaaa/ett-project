# Local Kubernetes with Minikube

Terraform is optional here; Minikube is usually installed directly on the workstation.

## Install

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

## Start

```bash
minikube start --cpus=4 --memory=8192 --driver=docker
minikube addons enable ingress
```

Using the bundled ingress addon avoids installing `ingress-nginx` via Helm (either works).

## Point kubectl at Minikube

```bash
kubectl config use-context minikube
```

## Next

Follow the root `README.md` to install the app Helm chart and optional monitoring/logging stacks.
