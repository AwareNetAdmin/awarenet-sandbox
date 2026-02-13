#!/bin/bash

# AwareNet Sandbox Deployment Script
# Syncs files to Google Cloud Storage bucket

BUCKET="gs://sandbox.awarenet.us"

echo "🚀 Deploying AwareNet Sandbox to $BUCKET"

# Sync all files to bucket
echo "📁 Syncing files..."
gsutil -m rsync -r -d . $BUCKET

# Set cache control headers
echo "⏰ Setting cache headers..."
gsutil -m setmeta -h "Cache-Control:public, max-age=3600" $BUCKET/*.html
gsutil -m setmeta -h "Cache-Control:public, max-age=86400" $BUCKET/assets/**

# Set website configuration
echo "🌐 Configuring website settings..."
gsutil web set -m index.html -e 404.html $BUCKET

# Make sure bucket is public
echo "🔓 Ensuring public access..."
gsutil iam ch allUsers:objectViewer $BUCKET

echo "✅ Deployment complete!"
echo "🌍 Site available at: https://sandbox.awarenet.us"
echo ""
echo "Note: DNS changes may take up to 24 hours to propagate globally."