#!/bin/bash

# AwareNet Sandbox Deployment Script
# Deploys site to Firebase Hosting

echo "🚀 Deploying AwareNet Sandbox to Firebase Hosting"

# Rebuild search index from current HTML files
echo "🔍 Rebuilding search index..."
node build-search-index.js
if [ $? -ne 0 ]; then
    echo "❌ Search index build failed!"
    exit 1
fi

# Authenticate using service account
KEY_FILE="$(pwd)/service-account-key.json"
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Service account key not found: $KEY_FILE"
    exit 1
fi

echo "🔐 Authenticating with service account..."
export GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE"

# Deploy to Firebase Hosting
echo "📦 Deploying to Firebase..."
firebase deploy --only hosting --non-interactive

if [ $? -eq 0 ]; then
    echo "✅ Deployment complete!"
    echo "🌍 Site available at:"
    echo "   → https://sandbox.awarenet.us"
    echo "   → https://awarenet.web.app"
else
    echo "❌ Deployment failed!"
    exit 1
fi
