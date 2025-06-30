#!/bin/bash
# Deploys the application to the local Minikube cluster.
#
# By default, it deploys the 'latest' tag.
# You can also deploy a specific version by providing a tag as an argument.
#
# Usage for latest: ./scripts/deploy.sh
# Usage for specific: ./scripts/deploy.sh <image-tag>

set -e # Exit immediately if any command fails.

# --- Configuration ---
IMAGE_BASE="harbeylefty17/fastapi-service"
DEPLOYMENT_NAME="fastapi-deployment"
NAMESPACE="fastapi-app"

# If a command-line argument (a specific tag) is provided, use it.
# Otherwise, default to 'latest' for convenience.
TAG=${1:-"latest"}
IMAGE="${IMAGE_BASE}:${TAG}"

echo "🚀 Starting deployment of version '${TAG}' to Minikube..."

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

echo "🔄 Updating the deployment image to ${IMAGE}..."
kubectl set image deployment/"$DEPLOYMENT_NAME" fastapi-container="$IMAGE" -n "$NAMESPACE" --record

echo "⏳ Waiting for the deployment rollout to complete. This may take a few minutes..."
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=5m

echo "✅ Deployment of version '${TAG}' successful!"
echo ""
echo "➡️  Next, run './scripts/healthcheck.sh' to verify the application is healthy." 