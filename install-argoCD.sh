#!/bin/bash

set -e

echo "Creating ArgoCD namespace..."
kubectl create namespace argocd || true

echo "Installing ArgoCD..."
kubectl apply -n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sleep 10
echo "Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
sleep 3

echo "Exposing ArgoCD Server..."
kubectl patch svc argocd-server \
-n argocd \
-p '{"spec":{"type":"LoadBalancer"}}'
sleep 2

echo "Waiting for LoadBalancer IP..."
sleep 60

echo "Getting ArgoCD URL..."
kubectl get svc argocd-server -n argocd

kubectl get svc argocd-server -n argocd >> argocd.details

echo "Fetching ArgoCD admin password..."
kubectl get secret argocd-initial-admin-secret \
-n argocd \
-o jsonpath="{.data.password}" | base64 -d >> argocd.details

echo "DONE"
