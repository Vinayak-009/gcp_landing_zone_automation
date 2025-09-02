locals {
  # This block takes the list of full paths, e.g., ["a/b/c", "a/d"], and creates
  # a set of all the required parent folders, e.g., {"a", "a/b", "a/b/c", "a/d"}.
  all_required_folders = toset(flatten([
    for path in var.folder_paths : [
      for i in range(length(split("/", path))) :
      join("/", slice(split("/", path), 0, i + 1))
    ]
  ]))

  # We pre-calculate all parent relationships into a simple map. This is what
  # breaks the dependency cycle for Terraform's planner.
  folder_parent_map = {
    for path in local.all_required_folders : path => {
      is_nested   = strcontains(path, "/")
      # If nested, calculate the parent path. If not, this value is null.
      parent_path = strcontains(path, "/") ? join("/", slice(split("/", path), 0, length(split("/", path)) - 1)) : null
    }
  }
}

# This resource block now has a very simple and clear dependency graph.
resource "google_folder" "main" {
  for_each = local.folder_parent_map

  display_name = basename(each.key)

  # The parent is now determined by a simple lookup in our map.
  # If it's nested, we depend on the parent folder. If not, we depend on the organization.
  parent = each.value.is_nested ? google_folder.main[each.value.parent_path].name : "organizations/${var.org_id}"
}

# Create all projects, looking up their parent folder from the resource above.
resource "google_project" "main" {
  for_each = { for p in var.projects : p.project_id => p }

  project_id      = each.value.project_id
  name            = each.value.project_name
  billing_account = var.billing_account
  folder_id       = google_folder.main[each.value.folder_path].folder_id
}
