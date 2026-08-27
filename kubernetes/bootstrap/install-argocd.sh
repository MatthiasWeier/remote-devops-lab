#!/bin/bash
# Bootstraps ArgoCD onto the K3s cluster.
#
# Run this once, after the cluster and Longhorn are up, before applying
# anything under kubernetes/apps/. Requires kubectl to already be configured
# against the cluster (e.g. KUBECONFIG pointing at the control-plane's
# /etc/rancher/k3s/k3s.yaml).

set -euo pipefail

ARGOCD_NAMESPACE="argocd"
ARGOCD_MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

echo "Creating '${ARGOCD_NAMESPACE}' namespace..."
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "Applying upstream ArgoCD manifests from ${ARGOCD_MANIFEST_URL}..."
kubectl apply -n "${ARGOCD_NAMESPACE}" -f "${ARGOCD_MANIFEST_URL}"

echo "Waiting for the argocd-server deployment to become available (this can take a few minutes)..."
kubectl -n "${ARGOCD_NAMESPACE}" rollout status deployment/argocd-server --timeout=300s

echo ""
echo "ArgoCD installed successfully."
echo ""
echo "Retrieve the initial admin password with:"
echo "  kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo ""
echo "Username is 'admin'. Access the UI with:"
echo "  kubectl -n ${ARGOCD_NAMESPACE} port-forward svc/argocd-server 8080:443"
echo ""
echo "Once logged in, delete the initial admin secret as recommended by upstream:"
echo "  kubectl -n ${ARGOCD_NAMESPACE} delete secret argocd-initial-admin-secret"
