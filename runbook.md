# Runbook: FastAPI Deployment

This runbook provides step-by-step instructions for deploying, monitoring, troubleshooting, and maintaining the FastAPI application in a Kubernetes environment.

---

## 1. Deployment

### Deploy Latest Version
```
./scripts/deploy.sh
```

### Deploy Specific Version
```
./scripts/deploy.sh <image-tag>
```

### Verify Deployment
- Check pod status:
  ```
  kubectl get pods -n fastapi-app
  ```
- Check Ingress:
  ```
  ./scripts/healthcheck.sh
  ```
- App should be accessible at the configured Ingress URL.

---

## 2. Rollback

### Roll Back to Previous Version
```
./scripts/rollback.sh
```

### Verify Rollback
- Check pod status and logs:
  ```
  kubectl get pods -n fastapi-app
  kubectl logs <pod-name> -n fastapi-app
  ```
- Confirm the app is running the previous image tag.

---

## 3. Health Checks

### Automated Health Check
```
./scripts/healthcheck.sh
```

### Manual Health Check
- Port-forward the service:
  ```
  kubectl port-forward -n fastapi-app svc/fastapi-service 8080:80
  ```
- Visit `http://localhost:8080/health` in your browser.
- Should return `{"status": "healthy", "timestamp": "2024-01-01T00:00:00Z"}`.

---

## 4. Monitoring

### Access Grafana
- Port-forward:
  ```
  kubectl port-forward -n monitoring svc/grafana-service 3000:3000
  ```
- Open [http://localhost:3000](http://localhost:3000)
- Login: `admin` / `admin123` (or check the `grafana-secret`)

### Access Prometheus
- Port-forward:
  ```
  kubectl port-forward -n monitoring svc/prometheus-service 9091:9090
  ```
- Open [http://localhost:9091](http://localhost:9091)

### Key Metrics
- `http_requests_total` (FastAPI app)
- Node Exporter metrics (system health)

---
## 5. Scaling 

### Adjust the number of replicas for the FastAPI deployment to simulate Alerts functionality
- Scale the deployment to the desired number of replicas. eg - 0
- Gracefully stops all running instances of the application by scaling the deployment to zero replicas. This is particularly useful for testing your monitoring and alerting systems by simulating an outage.
  ```
  kubectl scale deployment fastapi-deployment --replicas=0 -n fastapi-app
  ```
- Scale Back Up 
  ```
  kubectl scale deployment fastapi-deployment --replicas=2 -n fastapi-app
  ```

## 6. Troubleshooting

### Pod Not Starting / CrashLoopBackOff
- Describe the pod:
  ```
  kubectl describe pod <pod-name> -n fastapi-app
  ```
- Check logs:
  ```
  kubectl logs <pod-name> -n fastapi-app
  ```
- Common issues:
  - ImagePullBackOff: Check image tag and Docker Hub availability
  - Security policy violation: See section 6

### Ingress Not Working
- Check Ingress resource:
  ```
  kubectl get ingress -n fastapi-app
  kubectl describe ingress -n fastapi-app
  ```
- Ensure `minikube tunnel` is running (if using Minikube)
- Check `/etc/hosts` for correct hostname mapping

### Monitoring Not Working
- Check pod status in `monitoring` namespace:
  ```
  kubectl get pods -n monitoring
  ```
- Check Prometheus targets page for scrape errors

---

## 7. Security

### Pod Blocked by Security Policy
- Error: `forbidden: violates PodSecurity "restricted:latest" ...`
- Solution: Ensure your pod spec includes:
  - `securityContext.runAsNonRoot: true`
  - `securityContext.allowPrivilegeEscalation: false`
  - `securityContext.capabilities.drop: ["ALL"]`
  - `securityContext.seccompProfile.type: RuntimeDefault`

### Check RBAC
- List roles and bindings:
  ```
  kubectl get role,rolebinding -n fastapi-app
  ```
- Describe role:
  ```
  kubectl describe role fastapi-role -n fastapi-app
  ```

---