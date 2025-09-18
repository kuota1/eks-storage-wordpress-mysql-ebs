#!/usr/bin/env bash
set -euo pipefail

# --- Vars ---
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER="${CLUSTER:-wp-eks-demo}"
NODE_TYPE="${NODE_TYPE:-t3.small}"
NODES="${NODES:-2}"
NS="${NS:-portfolio-pvc-demo}"
WP_DB_PASS="${WP_DB_PASS:-SuperSegura_123}"

echo "[1/9] Create EKS cluster ($CLUSTER) in $AWS_REGION..."
eksctl create cluster \
  --name "$CLUSTER" \
  --region "$AWS_REGION" \
  --nodes "$NODES" --node-type "$NODE_TYPE" \
  --with-oidc \
  --managed

echo "[2/9] Update kubeconfig & check nodes..."
aws eks --region "$AWS_REGION" update-kubeconfig --name "$CLUSTER"
kubectl get nodes

echo "[3/9] Install EBS CSI addon..."
eksctl create addon --name aws-ebs-csi-driver --cluster "$CLUSTER" --region "$AWS_REGION" --force
aws eks describe-addon --cluster-name "$CLUSTER" --addon-name aws-ebs-csi-driver --region "$AWS_REGION" \
  --query 'addon.status' --output text

echo "[4/9] Create namespace & context..."
kubectl create ns "$NS" || true
kubectl config set-context --current --namespace="$NS"

echo "[5/9] Create MySQL secret..."
kubectl create secret generic mysql-root --from-literal=password="$WP_DB_PASS" || true

echo "[6/9] (Optional) Apply gp3 StorageClass if no default CSI present..."
# kubectl apply -f manifests/sc-gp3.yaml

echo "[7/9] Deploy MySQL (PVC + Deployment + Service)..."
kubectl apply -f manifests/pvc-mysql.yaml
kubectl apply -f manifests/mysql-deploy.yaml
kubectl rollout status deploy/mysql
kubectl get pvc

echo "[8/9] Deploy WordPress (PVC + LoadBalancer)..."
# Asegúrate de que manifests/wordpress.yaml tiene:
#   - WORDPRESS_DB_HOST=mysql
#   - WORDPRESS_DB_USER=root
#   - WORDPRESS_DB_PASSWORD (desde Secret)
#   - WORDPRESS_DB_NAME=wordpress   <-- IMPORTANTE
kubectl apply -f manifests/wordpress.yaml
kubectl rollout status deploy/wordpress
kubectl get svc wordpress -w
# Abre el EXTERNAL-IP en el navegador, instala WP, crea un post/imagen.

echo "[9/9] (Optional) Persistence check: restart WP pod..."
kubectl delete pod -l app=wordpress
kubectl wait --for=condition=Ready pod -l app=wordpress --timeout=120s
echo "✅ WordPress should still show your content after restart."
