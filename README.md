# Production-Ready FastAPI Application

This repository contains a containerized FastAPI application designed for a production-like deployment on Kubernetes. It includes a full CI/CD pipeline, a complete monitoring stack (Prometheus & Grafana), and robust security configurations (RBAC, Pod Security Standards).

## Project Structure

```
.
├── .github/workflows/      # GitHub Actions CI/CD pipeline
│   └── ci-cd.yaml
├── app/                    # FastAPI application source code
│   ├── main.py
│   └── Dockerfile
├── k8s/                    # Kubernetes manifests for the application
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── hpa.yaml
│   └── serviceaccount.yaml
├── monitoring/             # Kubernetes manifests for the monitoring stack
│   ├── prometheus-configmap.yaml
│   ├── grafana-deployment.yaml
│   └── ... (and other monitoring manifests)
├── scripts/                # Local deployment and management scripts
│   ├── deploy.sh
│   ├── healthcheck.sh
│   └── rollback.sh
├── security/               # Security policy manifests
│   ├── pod-security.yaml
│   └── rbac.yaml
└── README.md
```

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- `kubectl`
- A Docker Hub account

## Setup and Deployment

### 1. Start Local Kubernetes Cluster
Start Minikube to get your local Kubernetes environment running.
```bash
minikube start
```

### 2. Create Namespaces
The application and its monitoring stack are deployed in separate namespaces for better organization and security.
```bash
kubectl create namespace fastapi-app
kubectl create namespace monitoring
```

### 3. Deploy the Application
The `deploy.sh` script applies all necessary Kubernetes manifests and can deploy a specific version if a Docker image tag is provided.

**Deploy the `:latest` version:**
```bash
./scripts/deploy.sh
```

**Deploy a specific version (using commit SHA):**
```bash
./scripts/deploy.sh <commit-sha-tag>
```

### 4. CI/CD Pipeline (`ci-cd.yaml`)

The CI/CD pipeline is configured to run on every push to the `main` branch for changes within the `app/` directory.

**Pipeline Stages:**
1.  **Lint & Test:** Runs `flake8` for linting and `pytest` for unit tests.
2.  **Build & Push:** Builds the Docker image and pushes it to Docker Hub with two tags: `:latest` and the short commit SHA.

**Note:** The pipeline requires `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` to be configured as secrets in the GitHub repository settings.

## Management Scripts

### Health Check
The `healthcheck.sh` script checks the status of the deployment and verifies that the application is accessible via its Ingress endpoint.
```bash
./scripts/healthcheck.sh
```

### Rollback
The `rollback.sh` script performs a rollback to the previous deployment version.
```bash
./scripts/rollback.sh
```

## Monitoring

The monitoring stack includes Prometheus for metrics collection and Grafana for visualization.

### 1. Deploy the Monitoring Stack
```bash
kubectl apply -f monitoring/
```

### 2. Access Grafana
Forward the Grafana port to your local machine:
```bash
kubectl port-forward -n monitoring svc/grafana-service 3000:3000
```
- **URL:** `http://localhost:3000`
- **Username:** `admin`
- **Password:** `admin123` (retrieved from the `grafana-secret`)

### 3. Access Prometheus
Forward the Prometheus port to your local machine:
```bash
kubectl port-forward -n monitoring svc/prometheus-service 9091:9090
```
- **URL:** `http://localhost:9091`

### 4. Add Prometheus as a Grafana Data Source
- **URL:** `http://prometheus-service.monitoring.svc.cluster.local:9090`
- Navigate to Configuration -> Data Sources -> Add Prometheus.
- Use the URL above and click "Save & test".

## Security

- **RBAC:** A dedicated `ServiceAccount` (`fastapi-service-account`) is used for the application. It is bound to a `Role` with zero permissions, following the principle of least privilege.
- **Pod Security:** The `fastapi-app` namespace is enforced with the `restricted` Pod Security Standard, requiring pods to follow current pod hardening best practices and preventing them from running with privileged settings.
- **Network Policies:** Network policies are in place to control ingress and egress traffic to the application pods.
- **Secrets:** Application secrets (like API keys) and configuration are externalized using Kubernetes `Secrets` and `ConfigMaps`.