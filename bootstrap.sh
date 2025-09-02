#!/bin/bash
set -e # Exit immediately on any command failure

# --- Output Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info()    { echo -e "${YELLOW}[INFO] $1${NC}"; }
success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
fail()    { echo -e "${RED}[FAIL] $1${NC}"; }

# --- Begin Script ---
info "Starting GCP Onboarding Bootstrap Process..."
echo

# 1. Gather Inputs
read -p "Enter your Google Cloud Organization ID: " ORG_ID
read -p "Enter the Billing Account ID to link the new project to: " BILLING_ACCOUNT_ID
read -p "Enter the target GitHub Repository (e.g., YourName/YourRepo): " GITHUB_REPO

# Define resource names
PROJECT_ID="org-bootstrap-$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
SERVICE_ACCOUNT_NAME="github-automation-sa"
STATE_BUCKET_NAME="${PROJECT_ID}-tfstate"

echo
info "--- Configuration Summary ---"
echo "Organization ID:        $ORG_ID"
echo "Billing Account ID:     $BILLING_ACCOUNT_ID"
echo "GitHub Repo:            $GITHUB_REPO"
echo "New Project ID:         $PROJECT_ID"
echo "New Service Account:    $SERVICE_ACCOUNT_NAME"
echo "GCS State Bucket:       $STATE_BUCKET_NAME"
echo "-----------------------------"
read -p "Does this look correct? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# 2. Check Authentication
info "Checking for active gcloud authentication..."
CURRENT_USER=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
if [[ -z "$CURRENT_USER" ]]; then
    fail "No active gcloud account found. Please run 'gcloud auth login' and 'gcloud auth application-default login'."
    exit 1
fi
echo "Running as: $CURRENT_USER"
info "Ensure this account has 'Organization Administrator' and 'Billing Account Administrator' roles."
echo

# 3. Create Project
info "Creating bootstrap project '$PROJECT_ID'..."
gcloud projects create "$PROJECT_ID" --organization="$ORG_ID" --set-as-default

info "Linking project to billing account '$BILLING_ACCOUNT_ID'..."
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"

# 4. Enable Required APIs
info "Enabling required APIs (this may take a minute)..."
gcloud services enable \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com \
    serviceusage.googleapis.com \
    cloudbilling.googleapis.com \
    storage.googleapis.com \
    --project="$PROJECT_ID"

# 5. Create GCS Bucket for Terraform State
info "Creating GCS bucket '$STATE_BUCKET_NAME'..."
gsutil mb -p "$PROJECT_ID" -l "US" "gs://${STATE_BUCKET_NAME}"
gsutil versioning set on "gs://${STATE_BUCKET_NAME}"
success "GCS bucket created and versioning enabled."

# 6. Create Service Account
info "Creating service account '$SERVICE_ACCOUNT_NAME'..."
gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
    --display-name="GitHub Actions Automation SA" \
    --project="$PROJECT_ID"

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
success "Service Account created: $SERVICE_ACCOUNT_EMAIL"

# 7. Grant Org-level Permissions to Service Account
info "Granting organization-level permissions to Service Account..."
ROLES_TO_GRANT=(
    "roles/resourcemanager.folderCreator"
    "roles/resourcemanager.projectCreator"
    "roles/billing.user"
    "roles/resourcemanager.organizationViewer"
)

for role in "${ROLES_TO_GRANT[@]}"; do
    info "Granting '$role'..."
    gcloud organizations add-iam-policy-binding "$ORG_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role" \
        --condition=None > /dev/null
done
success "All organization-level roles granted."

# 8. Create and Download Service Account Key
info "Creating a JSON key for the Service Account..."
KEY_FILE="./${PROJECT_ID}-sa-key.json"
gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SERVICE_ACCOUNT_EMAIL"
success "Service Account key file created at: $KEY_FILE"

echo
success "Bootstrap complete! The final step is to create secrets in your GitHub repository."
echo -e "=========================================================================================="
echo -e "  ACTION REQUIRED: Add the following secrets to your GitHub repository:"
echo -e "  Go to: ${YELLOW}https://github.com/${GITHUB_REPO}/settings/secrets/actions${NC}"
echo -e "------------------------------------------------------------------------------------------"
echo -e "  1. Name: ${GREEN}GCP_SA_KEY${NC}"
echo -e "     Value: Copy the ENTIRE content of the file: ${YELLOW}${KEY_FILE}${NC}"
echo
echo -e "  2. Name: ${GREEN}TERRAFORM_STATE_BUCKET${NC}"
echo -e "     Value: ${YELLOW}${STATE_BUCKET_NAME}${NC}"
echo -e "=========================================================================================="
echo -e "${RED}IMPORTANT: Protect the key file '${KEY_FILE}'. It provides access to your GCP"
echo -e "organization. Do not commit it to any Git repository.${NC}"