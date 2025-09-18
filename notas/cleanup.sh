#!/usr/bin/env bash
set -euo pipefail
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER="${CLUSTER:-wp-eks-demo}"
NS="${NS:-portfolio-pvc-demo}"

kubectl delete -f manifests/wordpress.yaml || true
kubectl delete -f manifests/mysql-deploy.yaml || true
kubectl delete -f manifests/pvc-mysql.yaml || true
kubectl delete ns "$NS" || true
# kubectl delete -f manifests/sc-gp3.yaml || true

eksctl delete cluster --name "$CLUSTER" --region "$AWS_REGION"
