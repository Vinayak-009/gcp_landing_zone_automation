variable "org_id" {
  description = "The ID of the GCP Organization."
  type        = string
}

variable "billing_account" {
  description = "The Billing Account ID."
  type        = string
}

variable "folders" {
  description = "A hierarchical definition of folders and their projects."
  type        = any
  default     = []
}```

**File: `main.tf`**
```terraform
# Create the entire folder and project hierarchy using one recursive module.
module "gcp_hierarchy" {
  source = "./modules/folder_and_project"

  # This single module instance starts the entire recursive process.
  org_id            = var.org_id
  billing_account   = var.billing_account
  parent_id         = "organizations/${var.org_id}"
  parent_path       = "" # The root has no parent path
  folders_to_create = var.folders
}