# WordPress + MySQL on Kubernetes with Persistent Storage (PVC)

This project demonstrates the deployment of a WordPress site backed by a MySQL database, both running on Kubernetes using **PersistentVolumeClaims (PVCs)** for data durability. It's a real-world example of a two-tier application deployed on **AWS EKS** using dynamic volume provisioning (EBS) and LoadBalancer access.

---

##  Stack

- Kubernetes (tested on EKS)
- WordPress 6.3
- MySQL 8.0
- PersistentVolumeClaims (EBS-backed)
- AWS LoadBalancer (Service type: LoadBalancer)
- Namespace: `portfolio-pvc-demo`

---

## Project Structure

wordpress-pvc-demo/
├── manifests/
│ ├── wordpress.yaml
│ ├── mysql-deploy.yaml
│ └── pvc-mysql.yaml
│ └── sc-gp3.yaml
├── screenshots/
│ ├── error-debugging.png
│ ├── wordpress-running.png
│ ├── pods.png
├── notas/
│ └── troubleshooting.md
│ └── run.sh
│ └── cleanup.sh
├── README.md

## How to Deploy

1. **Create the namespace**:
   ```bash
   kubectl create ns portfolio-pvc-demo
Apply the PersistentVolumeClaims:

bash
Copy code
kubectl apply -f manifests/pvcs.yaml
Deploy MySQL and WordPress:

bash
Copy code
kubectl apply -f manifests/mysql-deployment.yaml
kubectl apply -f manifests/wordpress-deployment.yaml
Access the WordPress UI:

If using EKS:
Get the external IP from the LoadBalancer:

bash
Copy code
kubectl get svc wordpress -n portfolio-pvc-demo
Open in browser: http://<EXTERNAL-IP>

If testing locally (e.g. Minikube):

bash
Copy code
kubectl port-forward svc/wordpress 8080:80 -n portfolio-pvc-demo
open http://localhost:8080
Final Result
WordPress home page (Hello World) displayed.

Image uploaded via the Media Library.

Image persists after pod restart, confirming PVC usage.

Verified file presence using kubectl exec inside the pod:

bash
Copy code
cd /var/www/html/wp-content/uploads
ls -R
Troubleshooting & Lessons Learned
Issue: env block outside of containers
Symptom: Error applying wordpress-deployment.yaml — invalid field env.

Fix: Moved all env: definitions inside the containers: section, under spec.template.spec.containers[0].env.

Issue: PVC not bound (Pending)
Symptom: WordPress or MySQL pod stuck in Pending state.

Fix: Added storageClassName: gp3 explicitly or ensured gp3 was the default in the EKS cluster.

Issue: Unable to connect to MySQL
Symptom: WordPress install page failed due to DB connection error.

Fix: Confirmed the MySQL Service name matched WORDPRESS_DB_HOST. Also ensured the MYSQL_ROOT_PASSWORD secret was correctly applied.

Debug Techniques Used
kubectl describe pod to trace scheduling and volume binding issues.

kubectl logs on WordPress to debug DB connection errors.

kubectl exec into WordPress pod to verify file persistence.

Optional Enhancements
Add readinessProbe and livenessProbe to both deployments.

Configure backups for MySQL data.

Add Ingress + TLS for production.

Author
Roberto Carlos Rodríguez Guzmán
GitHub: @kuota1
AWS Certified DevOps Engineer – Professional
Location: Monterrey, Mexico