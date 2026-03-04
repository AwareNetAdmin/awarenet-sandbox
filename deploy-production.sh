#!/bin/bash

# AwareNet Production Deployment Script
# Deploys site to Firebase Hosting (production)

echo "🚀 Deploying AwareNet to PRODUCTION"
echo "⚠️  This will update the live production site!"
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled."
    exit 0
fi

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

# Deploy to Firebase Hosting (production target)
echo "📦 Deploying to Firebase (production)..."
firebase deploy --only hosting:production --non-interactive

if [ $? -eq 0 ]; then
    echo "✅ Production deployment complete!"
    echo "🌍 Production site available at:"
    echo "   → https://www.awarenet.us (once DNS is configured)"
    echo "   → https://awarenet-production.web.app"
else
    echo "❌ Deployment failed!"
    exit 1
fi
