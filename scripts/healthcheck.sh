#!/bin/bash
# Checks the health of the deployed FastAPI application via the Ingress.
# This script assumes the Ingress is routing for 'fastapi.test' and that
# you have a corresponding entry in your /etc/hosts file.
# It also requires 'minikube tunnel' to be running.

set -e

# --- Configuration ---
HOST="fastapi.test"
HEALTH_ENDPOINT="/health"
URL="http://${HOST}${HEALTH_ENDPOINT}"
MAX_RETRIES=12
RETRY_INTERVAL=10

echo "🏥 Starting health check via Ingress for host '$HOST'..."
echo "   (This requires 'minikube tunnel' to be running and /etc/hosts to be configured)"

# --- Perform Health Check with Retries ---
echo "🩺 Attempting to reach the health endpoint at: $URL"

for ((i=1; i<=MAX_RETRIES; i++)); do
    # Use curl to check the endpoint.
    # We send the request to localhost (127.0.0.1) where the minikube tunnel is listening.
    # The -H 'Host: ...' header tells the Ingress controller which service we want to reach.
    echo "   ...checking (attempt $i/$MAX_RETRIES)..."
    if curl --fail --silent --show-error --max-time 15 -H "Host: ${HOST}" http://127.0.0.1${HEALTH_ENDPOINT}; then
        echo "✅ Health check successful! The application is up and responding correctly via Ingress."
        exit 0
    fi

    if [ $i -eq $MAX_RETRIES ]; then
        echo "❌ Health check FAILED after $MAX_RETRIES attempts."
        echo "   Troubleshooting steps:"
        echo "   1. Is 'minikube tunnel' running in a separate terminal?"
        echo "   2. Have you mapped '$HOST' to 127.0.0.1 in your /etc/hosts file?"
        echo "   3. Is the Ingress controller running correctly? ('kubectl get pods -n ingress-nginx')"
        exit 1
    fi

    sleep $RETRY_INTERVAL
done 