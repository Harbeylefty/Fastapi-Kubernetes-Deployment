#!/bin/bash
# Deploys a SPECIFIC version of the application to the local Minikube cluster.
# This script requires a tag (e.g., a git commit SHA) to be provided as an argument.
#
# Usage: ./scripts/deploy.sh <image-tag>
# Example: ./scripts/deploy.sh a1b2c3d4e5f6

set -e # Exit immediately if any command fails.

# --- Argument Check ---
if [ -z "$1" ]; then
    echo "❌ Error: No image tag provided."
    echo "   An image tag (like a git commit SHA) is required."
    echo "   Usage: $0 <image-tag>"
    exit 1
fi

# --- Configuration ---
IMAGE_BASE="harbeylefty17/fastapi-service"
TAG=$1
IMAGE="${IMAGE_BASE}:${TAG}"
DEPLOYMENT_NAME="fastapi-deployment"
NAMESPACE="default"

echo "🚀 Starting deployment of specific version '${TAG}' to Minikube..."

# --- Pre-flight Checks ---
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl command could not be found. Please install it."
    exit 1
fi

if ! minikube status &> /dev/null || ! minikube status | grep -q "Running"; then
    echo "⚠️ Minikube is not running. Please start it with 'minikube start'."
    exit 1
fi

echo "✅ Pre-flight checks passed."

# --- Deployment ---
echo "📦 Applying Kubernetes manifests from 'k8s/' to ensure objects exist..."
kubectl apply -f k8s/ -n $NAMESPACE

echo "🔄 Updating the deployment's container image to use the precise version: $IMAGE..."
kubectl set image deployment/$DEPLOYMENT_NAME fastapi-app=$IMAGE -n $NAMESPACE

echo "⏳ Waiting for the deployment rollout to complete. This may take a few minutes..."
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=5m

echo "✅ Deployment of version '${TAG}' successful!"
echo ""
echo "➡️  Next, run './scripts/healthcheck.sh' to verify the application is healthy." 