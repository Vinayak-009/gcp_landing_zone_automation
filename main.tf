locals {
  # This block takes the list of full paths, e.g., ["a/b/c", "a/d"], and creates
  # a set of all the required parent folders, e.g., {"a", "a/b", "a/b/c", "a/d"}.
  # This ensures that we create every folder in the hierarchy, in the correct order.
  all_required_folders = toset(flatten([
    for path in var.folder_paths : [
      for i in range(length(split("/", path))) :
      join("/", slice(split("/", path), 0, i + 1))
    ]
  ]))
}

# This single resource block creates ALL folders, no matter how deep.
# It intelligently figures out the parent of each folder based on its path.
resource "google_folder" "main" {
  for_each = local.all_required_folders

  display_name = basename(each.value)

  # Determine the parent. If the path has no '/', the parent is the organization.
  # Otherwise, the parent is the folder resource corresponding to the path's parent directory.
  parent = contains(split("/", each.value), "/") ?
    google_folder.main[dirname(each.value)].name :
    "organizations/${var.org_id}"
}

# Create all projects, looking up their parent folder from the resource above.
resource "google_project" "main" {
  for_each = { for p in var.projects : p.project_id => p }

  project_id      = each.value.project_id
  name            = each.value.project_name
  billing_account = var.billing_account
  folder_id       = google_folder.main[each.value.folder_path].folder_id
}

