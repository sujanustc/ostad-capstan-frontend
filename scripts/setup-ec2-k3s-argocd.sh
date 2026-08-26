#!/usr/bin/env bash
# ==============================================================================
# EC2 Setup Script: Docker + K3s + Argo CD
# Run this script on your EC2 instance (Ubuntu 24.04 / 22.04)
# Public IP: 13.203.161.35
# ==============================================================================

set -e

echo "=== [1/6] Updating System & Installing Docker ==="
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates git jq

if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker ubuntu
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

echo "=== [2/6] Installing K3s (Lightweight Kubernetes) ==="
if ! command -v k3s &> /dev/null; then
    curl -sfL https://get.k3s.io | sh -
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
    export KUBECONFIG=~/.kube/config
    echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
    echo "K3s installed successfully."
else
    echo "K3s is already installed."
fi

echo "=== [3/6] Creating Kubernetes Namespaces (dev, stage, prod, argocd) ==="
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace stage --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "=== [4/6] Installing Argo CD ==="
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== [5/6] Patching Argo CD Server to NodePort (Port 30808) ==="
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"name": "https", "port": 443, "targetPort": 8080, "nodePort": 30808}]}}'

echo "=== [6/6] Waiting for Argo CD Server Pods to be Ready ==="
kubectl rollout status deployment argocd-server -n argocd --timeout=180s || true

# Get initial admin password
ARGO_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode 2>/dev/null || echo "Check argocd-initial-admin-secret")

echo "=========================================================================="
echo " SETUP COMPLETED SUCCESSFULLY!"
echo "=========================================================================="
echo " Kubernetes Cluster Status:"
kubectl get nodes
echo ""
echo " Argo CD Access Details:"
echo "   URL:      https://13.203.161.35:30808"
echo "   Username: admin"
echo "   Password: ${ARGO_PASSWORD}"
echo "=========================================================================="
