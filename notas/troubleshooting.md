export AWS_REGION=us-east-1
export CLUSTER=wp-eks-demo
export NODE_TYPE=t3.small
export NODES=2
# si usas SSO:
# export AWS_PROFILE=mi-sso

eksctl create cluster \
  --name $CLUSTER \
  --region $AWS_REGION \
  --nodes $NODES --node-type $NODE_TYPE \
  --with-oidc \
  --managed
# si usas SSO añade:  --profile $AWS_PROFILE


aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER
kubectl get nodes

eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER --region $AWS_REGION --force
aws eks describe-addon --cluster-name $CLUSTER --addon-name aws-ebs-csi-driver --region $AWS_REGION \
  --query 'addon.status' --output text
# Debe responder: ACTIVE
# Namespace y contexto
kubectl create ns portfolio-pvc-demo
kubectl config set-context --current --namespace=portfolio-pvc-demo

# Secret para MySQL root
kubectl create secret generic mysql-root --from-literal=password='SuperSegura_123'

# (Solo si NO tienes StorageClass default de ebs.csi.aws.com)
# kubectl apply -f manifests/sc-gp3.yaml

# PVC + MySQL
kubectl apply -f manifests/pvc-mysql.yaml
kubectl apply -f manifests/mysql-deploy.yaml
kubectl rollout status deploy/mysql
kubectl get pods,pvc,svc

# WordPress (PVC + LoadBalancer)
kubectl apply -f manifests/wordpress.yaml
kubectl rollout status deploy/wordpress
kubectl get svc wordpress -w   # espera el EXTERNAL-IP

# Después de instalar WordPress y crear contenido:
kubectl delete pod -l app=wordpress
kubectl wait --for=condition=Ready pod -l app=wordpress --timeout=120s
# Refresca el sitio: tu contenido debe seguir ahí

kubectl delete -f manifests/wordpress.yaml
kubectl delete -f manifests/mysql-deploy.yaml
kubectl delete -f manifests/pvc-mysql.yaml
kubectl delete ns portfolio-pvc-demo

eksctl delete cluster --name $CLUSTER --region $AWS_REGION

PVC Pending → no hay StorageClass CSI por defecto:

kubectl get sc
kubectl describe pvc <name>
# aplicar sc-gp3.yaml y recrear PVC (storageClassName es inmutable)


MySQL OK pero WP falla conexión:

kubectl run mysql-client --rm -it --image=mysql:8.0 -- bash
mysql -hmysql -uroot -p"$WP_DB_PASS" -e "CREATE DATABASE IF NOT EXISTS wordpress;"
# Asegura WORDPRESS_DB_NAME=wordpress en wordpress.yaml
kubectl logs deploy/wordpress --tail=80


Service LoadBalancer sin IP:

kubectl describe svc wordpress
# esperar 2–5 min; revisar permisos de cloud provider si tarda demasiado