#!/bin/bash

# AwareNet Sandbox Deployment Script
# Syncs files to Google Cloud Storage bucket

BUCKET="gs://sandbox.awarenet.us"

echo "🚀 Deploying AwareNet Sandbox to $BUCKET"

# Authenticate using service account
echo "🔐 Authenticating with service account..."
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/service-account-key.json"
~/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"

# Sync all files to bucket
echo "📁 Syncing files..."
~/google-cloud-sdk/bin/gsutil -m rsync -r -d . $BUCKET

# Set cache control headers
echo "⏰ Setting cache headers..."
~/google-cloud-sdk/bin/gsutil -m setmeta -h "Cache-Control:public, max-age=3600" $BUCKET/*.html
~/google-cloud-sdk/bin/gsutil -m setmeta -h "Cache-Control:public, max-age=86400" $BUCKET/logo.svg

# Set website configuration
echo "🌐 Configuring website settings..."
~/google-cloud-sdk/bin/gsutil web set -m index.html -e 404.html $BUCKET

# Make sure bucket is public
echo "🔓 Ensuring public access..."
~/google-cloud-sdk/bin/gsutil iam ch allUsers:objectViewer $BUCKET

echo "✅ Deployment complete!"
echo "🌍 Site available at: https://sandbox.awarenet.us"
echo ""
echo "Note: DNS changes may take up to 24 hours to propagate globally."