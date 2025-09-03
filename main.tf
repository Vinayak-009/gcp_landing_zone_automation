# Create all folders from a simple flat list.
resource "google_folder" "main" {
  for_each = { for folder in var.folders : folder.name => folder }

  display_name = each.value.name

  # The parent is now explicitly defined in the data, making dependencies simple.
  # If the parent is 'org', it belongs to the organization.
  # Otherwise, it belongs to another folder in this same resource block.
  parent = each.value.parent == "org" ? "organizations/${var.org_id}" : google_folder.main[each.value.parent].name
}

# Create all projects, looking up their parent folder from the resource above.
resource "google_project" "main" {
  for_each = { for p in var.projects : p.project_id => p }

  project_id      = each.value.project_id
  name            = each.value.project_name
  billing_account = var.billing_account
  folder_id       = google_folder.main[each.value.parent_folder].folder_id
}
