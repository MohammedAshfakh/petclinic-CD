#!/bin/bash

set -e

echo "======================================"
echo "🚀 Installing Argo CD using Helm"
echo "======================================"

# Variables
NAMESPACE="argocd"
RELEASE="argocd"
CHART="argo/argo-cd"

echo "📦 Adding Helm repo..."
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update

echo "📁 Creating namespace..."
kubectl create namespace $NAMESPACE || true

echo "🚀 Installing Argo CD..."
helm install $RELEASE $CHART -n $NAMESPACE

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n $NAMESPACE --timeout=300s

echo "🌐 Exposing Argo CD server as LoadBalancer..."
kubectl patch svc argocd-server -n $NAMESPACE \
  -p '{"spec":{"type":"LoadBalancer"}}'

echo "⏳ Waiting for LoadBalancer to assign external IP..."
sleep 30

echo "======================================"
echo "📡 Argo CD Service Info:"
echo "======================================"
kubectl get svc argocd-server -n $NAMESPACE

echo "======================================"
echo "🔐 Fetching Argo CD Admin Password"
echo "======================================"

PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n $NAMESPACE \
  -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "✅ LOGIN DETAILS:"
echo "--------------------------------------"
echo "🌍 URL: http://$(kubectl get svc argocd-server -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "👤 Username: admin"
echo "🔑 Password: $PASSWORD"
echo "--------------------------------------"

echo "🎉 Argo CD installation completed!"
