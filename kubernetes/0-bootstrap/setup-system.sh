#!/bin/bash
echo "Start K3s installation"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --disable=traefik --disable=servicelb --write-kubeconfig-mode=644

echo "Install 'system' applications next"
kubectl apply -k .
kubectl -n argocd rollout status deployment/argocd-server --timeout=5m
kubectl -n argocd rollout status deployment/argocd-applicationset-controller --timeout=5m
sleep 10

echo "Install 'system' applications next and wait installations"
kubectl apply -f argocd/applicationSet-system.yaml
sleep 10
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application --all --timeout=5m