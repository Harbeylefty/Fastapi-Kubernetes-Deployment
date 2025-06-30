#!/bin/bash
# Rolls back the application to the previously deployed, stable version.
#
# Usage: ./scripts/rollback.sh

set -e

# --- Configuration ---
DEPLOYMENT_NAME="fastapi-deployment"
NAMESPACE="fastapi-app"

echo "⏪ Starting rollback for deployment '$DEPLOYMENT_NAME'..."

# --- Check Deployment History ---
# We check if there's even a history to roll back to.
# `kubectl rollout history` returns a header line, so a deployment with one
# previous version will have 3 lines (Header, Rev 2, Rev 1).
echo "🔍 Checking deployment history..."
REVISION_COUNT=$(kubectl rollout history deployment/$DEPLOYMENT_NAME -n $NAMESPACE | wc -l)

# The result of wc -l can have leading whitespace on some systems, so we trim it.
REVISION_COUNT_TRIMMED=$(echo $REVISION_COUNT | xargs)

if [ "$REVISION_COUNT_TRIMMED" -lt 3 ]; then
    echo "⚠️ No previous deployment history found. Cannot perform a rollback."
    exit 1
fi

echo "   Found previous versions. Proceeding with rollback."

# --- Perform Rollback ---
echo "🔄 Undoing the last deployment to revert to the previous revision..."
kubectl rollout undo deployment/$DEPLOYMENT_NAME -n $NAMESPACE

echo "⏳ Waiting for the rollback to complete..."
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=5m

# --- Verification ---
echo "🔍 Verifying rollback status..."
# Get the image of the newly rolled-back deployment to show which version is now active.
CURRENT_IMAGE=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o=jsonpath='{.spec.template.spec.containers[0].image}')

echo "✅ Rollback successful!"
echo "   The deployment is now running the previous stable version."
echo "   Current active image: $CURRENT_IMAGE" 