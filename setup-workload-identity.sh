#!/bin/bash
set -e

# Configuration - can be overridden via environment variables
PROJECT_ID="${PROJECT_ID:-gen-lang-client-0765258695}"
PROJECT_NUMBER="${PROJECT_NUMBER:-142444819227}"
POOL_NAME="${POOL_NAME:-gh-pool}"
PROVIDER_NAME="${PROVIDER_NAME:-gh-provider}"
SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-gh-actions-deployer}"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
REGION="${REGION:-us-east4}"

# GitHub repository - can be overridden via environment variable
GITHUB_REPO="${GITHUB_REPO:-lewis-mi/vibe-check-backend}"
REPO_OWNER="${GITHUB_REPO%/*}"

echo "=== Setting up Workload Identity Federation for GitHub Actions ==="
echo "Project: ${PROJECT_ID}"
echo "GitHub Repo: ${GITHUB_REPO}"
echo ""

# Enable required APIs
echo "1. Enabling required APIs..."
gcloud services enable iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  sts.googleapis.com \
  --project="${PROJECT_ID}"

# Create Workload Identity Pool
echo ""
echo "2. Creating Workload Identity Pool: ${POOL_NAME}..."
if gcloud iam workload-identity-pools describe "${POOL_NAME}" \
  --location="global" \
  --project="${PROJECT_ID}" &>/dev/null; then
  echo "   Pool already exists, skipping..."
else
  gcloud iam workload-identity-pools create "${POOL_NAME}" \
    --location="global" \
    --display-name="GitHub Actions Pool" \
    --project="${PROJECT_ID}"
fi

# Create Workload Identity Provider
echo ""
echo "3. Creating Workload Identity Provider: ${PROVIDER_NAME}..."
if gcloud iam workload-identity-pools providers describe "${PROVIDER_NAME}" \
  --location="global" \
  --workload-identity-pool="${POOL_NAME}" \
  --project="${PROJECT_ID}" &>/dev/null; then
  echo "   Provider already exists, skipping..."
else
  gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_NAME}" \
    --location="global" \
    --workload-identity-pool="${POOL_NAME}" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
    --attribute-condition="assertion.repository_owner == '${REPO_OWNER}'" \
    --project="${PROJECT_ID}"
fi

# Create Service Account
echo ""
echo "4. Creating Service Account: ${SERVICE_ACCOUNT_EMAIL}..."
if gcloud iam service-accounts describe "${SERVICE_ACCOUNT_EMAIL}" \
  --project="${PROJECT_ID}" &>/dev/null; then
  echo "   Service account already exists, skipping..."
else
  gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
    --display-name="GitHub Actions Deployer" \
    --project="${PROJECT_ID}"
fi

# Grant permissions to the service account
echo ""
echo "5. Granting permissions to service account..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/run.developer"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

# Allow GitHub Actions to impersonate the service account
echo ""
echo "6. Allowing GitHub Actions to impersonate service account..."
gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_REPO}" \
  --project="${PROJECT_ID}"

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Your Workload Identity Provider:"
echo "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"
echo ""
echo "Service Account:"
echo "${SERVICE_ACCOUNT_EMAIL}"
echo ""
echo "You can now use these in your GitHub Actions workflow."
