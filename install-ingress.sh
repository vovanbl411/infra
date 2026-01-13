#!/bin/bash

# Установка NGINX Ingress Controller для Kubernetes кластера

echo "Установка NGINX Ingress Controller..."

# Добавление репозитория Helm (если не установлен)
if ! command -v helm &> /dev/null; then
    echo "Helm не найден. Устанавливаем Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Добавление репозитория ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Установка NGINX Ingress Controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.type=LoadBalancer \
    --set controller.service.externalIPs={YOUR_FLOATING_IP} \
    --wait

echo "NGINX Ingress Controller установлен!"

# Проверка установки
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

echo "Ingress Controller готов к работе!"
echo "External IP: $(kubectl get svc -n ingress-nginx -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')"