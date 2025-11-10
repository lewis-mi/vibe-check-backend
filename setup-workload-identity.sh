#!/bin/bash

# Setup script for Google Cloud Workload Identity Federation with GitHub Actions
# This script creates the necessary workload identity pool and provider for secure authentication

set -e

PROJECT_ID="gen-lang-client-0765258695"
PROJECT_NUMBER="142444819227"
POOL_NAME="gh-pool"
PROVIDER_NAME="gh-provider"
SERVICE_ACCOUNT="gh-actions-deployer@${PROJECT_ID}.iam.gserviceaccount.com"
REPO_OWNER="lewis-mi"  # Update this to your GitHub username/org
REPO_NAME="vibe-check-backend"

echo "Setting up Workload Identity Federation for GitHub Actions..."
echo "Project ID: $PROJECT_ID"
echo "Project Number: $PROJECT_NUMBER"

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable iamcredentials.googleapis.com \
  --project="${PROJECT_ID}"

gcloud services enable cloudresourcemanager.googleapis.com \
  --project="${PROJECT_ID}"

# Create Workload Identity Pool
echo "Creating Workload Identity Pool: ${POOL_NAME}..."
gcloud iam workload-identity-pools create "${POOL_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool" \
  --description="Workload Identity Pool for GitHub Actions" || echo "Pool may already exist"

# Create Workload Identity Provider
echo "Creating Workload Identity Provider: ${PROVIDER_NAME}..."
gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_NAME}" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${REPO_OWNER}'" \
  --issuer-uri="https://token.actions.githubusercontent.com" || echo "Provider may already exist"

# Create service account if it doesn't exist
echo "Checking/Creating service account: ${SERVICE_ACCOUNT}..."
gcloud iam service-accounts create gh-actions-deployer \
  --project="${PROJECT_ID}" \
  --display-name="GitHub Actions Deployer" \
  --description="Service account for GitHub Actions to deploy to Cloud Run" || echo "Service account may already exist"

# Grant necessary roles to the service account
echo "Granting roles to service account..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/storage.admin"

# Allow the Workload Identity Pool to impersonate the service account
echo "Configuring Workload Identity Pool to impersonate service account..."
gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${REPO_OWNER}/${REPO_NAME}"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Workload Identity Provider ID:"
echo "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"
echo ""
echo "Service Account:"
echo "${SERVICE_ACCOUNT}"
echo ""
echo "You can now use these values in your GitHub Actions workflow."
