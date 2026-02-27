#!/bin/bash

# AwareNet Sandbox Deployment Script
# Uploads site files to Google Cloud Storage bucket

BUCKET="gs://sandbox.awarenet.us"
GSUTIL=~/google-cloud-sdk/bin/gsutil

echo "🚀 Deploying AwareNet Sandbox to $BUCKET"

# Rebuild search index from current HTML files
echo "🔍 Rebuilding search index..."
node build-search-index.js
if [ $? -ne 0 ]; then
    echo "❌ Search index build failed!"
    exit 1
fi

# Authenticate using service account (skip if key not present — already authenticated)
KEY_FILE="$(pwd)/service-account-key.json"
if [ -f "$KEY_FILE" ]; then
    echo "🔐 Authenticating with service account..."
    export GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE"
    ~/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file="$KEY_FILE"
fi

# Upload all HTML files explicitly
echo "📁 Uploading HTML files..."
for f in *.html; do
    [ -f "$f" ] || continue
    echo "  → $f"
    $GSUTIL -q cp "$f" "$BUCKET/$f"
done

# Upload supporting assets
echo "📁 Uploading assets..."
for f in logo.svg *.jpg *.png; do
    [ -f "$f" ] || continue
    echo "  → $f"
    $GSUTIL -q cp "$f" "$BUCKET/$f"
done

# Upload search files
echo "📁 Uploading search files..."
for f in search.js search-index.json; do
    [ -f "$f" ] || continue
    echo "  → $f"
    $GSUTIL -q cp "$f" "$BUCKET/$f"
done

# Set cache control headers (no-cache for sandbox testing)
echo "⏰ Setting cache headers..."
$GSUTIL -m setmeta -h "Cache-Control:no-cache, no-store, must-revalidate" "$BUCKET"/*.html
$GSUTIL -m setmeta -h "Cache-Control:no-cache, no-store, must-revalidate" "$BUCKET/logo.svg"

# Set website configuration
echo "🌐 Configuring website settings..."
$GSUTIL web set -m index.html -e 404.html $BUCKET

# Make sure bucket is public
echo "🔓 Ensuring public access..."
$GSUTIL iam ch allUsers:objectViewer $BUCKET

echo "✅ Deployment complete!"
echo "🌍 Site available at: https://sandbox.awarenet.us"
