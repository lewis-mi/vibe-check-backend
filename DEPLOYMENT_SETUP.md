# Deployment Setup Guide

## Issue
The GitHub Actions deployment is failing with a Workload Identity Federation error because the identity pool and provider haven't been created yet in Google Cloud.

## Solution Options

### Option 1: Workload Identity Federation (Recommended - Most Secure)

This is the recommended approach as it doesn't require storing long-lived credentials.

#### Steps:

1. **Install and authenticate with gcloud CLI** (if not already done):
   ```bash
   gcloud auth login
   gcloud config set project gen-lang-client-0765258695
   ```

2. **Run the setup script**:
   ```bash
   chmod +x setup-workload-identity.sh
   ./setup-workload-identity.sh
   ```

3. **Verify the setup**:
   ```bash
   gcloud iam workload-identity-pools describe gh-pool \
     --location=global \
     --project=gen-lang-client-0765258695
   ```

4. **Push your code** - The workflow should now work!

---

### Option 2: Service Account Key (Simpler - Less Secure)

If you need to deploy immediately and can't set up Workload Identity Federation right now, use this alternative.

#### Steps:

1. **Create a service account key**:
   ```bash
   gcloud iam service-accounts keys create key.json \
     --iam-account=gh-actions-deployer@gen-lang-client-0765258695.iam.gserviceaccount.com
   ```

2. **Add the key to GitHub Secrets**:
   - Go to your repository on GitHub
   - Navigate to Settings > Secrets and variables > Actions
   - Click "New repository secret"
   - Name: `GCP_SA_KEY`
   - Value: Paste the entire contents of `key.json`
   - Click "Add secret"

3. **Delete the local key file** (important for security):
   ```bash
   rm key.json
   ```

4. **Update your workflow** to use the alternative authentication:
   - Change the workflow to use `deploy-with-sa-key.yml` (see below)

5. **Alternative workflow file** (`.github/workflows/deploy-with-sa-key.yml`):
   ```yaml
   name: Deploy to Cloud Run (Service Account Key)

   on:
     push:
       branches: [ "main" ]

   jobs:
     deploy:
       runs-on: ubuntu-latest

       steps:
         - name: Checkout
           uses: actions/checkout@v4

         - name: Auth to Google Cloud
           uses: google-github-actions/auth@v2
           with:
             credentials_json: ${{ secrets.GCP_SA_KEY }}

         - name: Setup gcloud
           uses: google-github-actions/setup-gcloud@v2
           with:
             project_id: gen-lang-client-0765258695

         - name: Deploy to Cloud Run from source
           run: |
             gcloud run deploy vibe-check-backend \
               --source . \
               --region us-east4 \
               --allow-unauthenticated
   ```

---

## Verification

After setup, trigger a deployment by pushing to the main branch:

```bash
git add .
git commit -m "Test deployment"
git push origin main
```

Then check the GitHub Actions tab in your repository to see the deployment status.

## Troubleshooting

### Error: "Permission denied"
- Ensure the service account has the necessary roles (run.admin, iam.serviceAccountUser, storage.admin)

### Error: "Pool or provider not found"
- Wait a few minutes after running the setup script, as it can take time to propagate
- Verify the pool exists: `gcloud iam workload-identity-pools list --location=global`

### Error: "Failed to generate token"
- Check that the repository owner in the setup script matches your GitHub username/organization
- Verify the attribute condition in the provider configuration
