# Create all folders passed to this level of recursion
resource "google_folder" "this" {
  for_each = { for f in var.folders_to_create : f.name => f }

  display_name = each.value.name
  parent       = var.parent_id
}

# Create all projects defined within each folder at this level
resource "google_project" "this" {
  # We flatten the list of projects from all folders at this level
  for_each = { for f in var.folders_to_create for p in lookup(f, "projects", []) : p.project_id => {
    project_id   = p.project_id
    project_name = p.project_name
    folder_name  = f.name # Get the parent folder name for the folder_id lookup
  } }

  project_id      = each.value.project_id
  name            = each.value.project_name
  billing_account = var.billing_account
  folder_id       = google_folder.this[each.value.folder_name].id
}

# RECURSION: Call this module again for the children of each folder
module "children" {
  # THIS IS THE FIX: Changed source from "../folder_and_project" to "./"
  source = "./" 

  for_each = { for f in var.folders_to_create : f.name => f if lookup(f, "children", null) != null }

  org_id            = var.org_id
  billing_account   = var.billing_account
  parent_id         = google_folder.this[each.key].name
  parent_path       = var.parent_path == "" ? each.key : "${var.parent_path}/${each.key}"
  folders_to_create = each.value.children
}
