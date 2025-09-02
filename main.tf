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

  # We pre-calculate the parent for every folder. This is more explicit and avoids cycles.
  folder_parents = {
    for path in local.all_required_folders : path =>
    # If the path contains a "/", its parent is the directory path.
    # Otherwise, its parent is the organization.
    contains(path, "/") ? dirname(path) : "organizations/${var.org_id}"
  }
}

# This resource block now has a much simpler dependency graph.
resource "google_folder" "main" {
  for_each = local.all_required_folders

  display_name = basename(each.key)

  # For the parent, we check our pre-calculated map. If the parent is another
  # folder, we look it up. Otherwise, we use the organization ID directly.
  # THIS IS THE CORRECTED LINE:
  parent = substr(local.folder_parents[each.key], 0, 13) == "organizations" ? local.folder_parents[each.key] : google_folder.main[local.folder_parents[each.key]].name
}

# Create all projects, looking up their parent folder from the resource above.
resource "google_project" "main" {
  for_each = { for p in var.projects : p.project_id => p }

  project_id      = each.value.project_id
  name            = each.value.project_name
  billing_account = var.billing_account
  folder_id       = google_folder.main[each.value.folder_path].folder_id
}
