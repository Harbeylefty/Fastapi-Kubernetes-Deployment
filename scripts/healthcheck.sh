#!/bin/bash
# Checks the health of the deployed FastAPI application.
# This script requires 'minikube tunnel' to be running in a separate terminal
# for the LoadBalancer IP to be accessible.

set -e

# --- Configuration ---
SERVICE_NAME="fastapi-service"
NAMESPACE="default"
HEALTH_ENDPOINT="/health"
MAX_RETRIES=12
RETRY_INTERVAL=10 # in seconds

echo "🏥 Starting health check for the service '$SERVICE_NAME'..."

# --- Get Service URL ---
# We loop to give the LoadBalancer time to get an IP address from 'minikube tunnel'.
echo "🔄 Attempting to find the service's external IP address..."
URL=""
for ((i=1; i<=MAX_RETRIES; i++)); do
    # Attempt to get the IP address from the service status.
    IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    
    if [ -n "$IP" ]; then
        # Assuming the service is exposed on port 80. Adjust if necessary.
        URL="http://${IP}${HEALTH_ENDPOINT}"
        echo "✅ Service IP found: $IP"
        break
    fi

    if [ $i -eq $MAX_RETRIES ]; then
        echo "❌ Error: Could not get the service's LoadBalancer IP after $MAX_RETRIES attempts."
        echo "   Troubleshooting steps:"
        echo "   1. Is 'minikube tunnel' running in a separate terminal?"
        echo "   2. Is the service '$SERVICE_NAME' of type LoadBalancer?"
        exit 1
    fi

    echo "   ...waiting for LoadBalancer IP (attempt $i/$MAX_RETRIES). Retrying in $RETRY_INTERVAL seconds."
    sleep $RETRY_INTERVAL
done

# --- Perform Health Check ---
echo "🩺 Performing GET request to the health endpoint: $URL"

# Use curl to check the endpoint.
# --fail: exits with a non-zero status code if the HTTP response is 4xx or 5xx.
# --silent: hides the progress meter.
# --show-error: shows an error message if curl fails.
# --max-time: sets a timeout for the request.
if curl --fail --silent --show-error --max-time 15 "$URL" | grep -q '"status": ?"healthy"'; then
    echo "✅ Health check successful! The application is up and responding correctly."
else
    echo "❌ Health check FAILED. The application endpoint is either not reachable or not returning a healthy status."
    echo "   Consider running './scripts/rollback.sh' to revert to the previous version."
    exit 1
fi 