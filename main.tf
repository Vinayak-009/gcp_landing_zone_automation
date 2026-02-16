locals {
  # Filter folders by level. 
  # (Assuming your JSON structure from previous steps)
  level_1 = [for f in var.folders : f if f.parent == "org"]
  level_2 = [for f in var.folders : f if contains([for x in local.level_1 : x.name], f.parent)]
  level_3 = [for f in var.folders : f if contains([for x in local.level_2 : x.name], f.parent)]
  level_4 = [for f in var.folders : f if contains([for x in local.level_3 : x.name], f.parent)]
}

# --- 1. FOLDER HIERARCHY ---

resource "google_folder" "l1" {
  for_each     = { for f in local.level_1 : f.name => f }
  display_name = each.value.name
  parent       = "organizations/${var.org_id}"
}

resource "google_folder" "l2" {
  for_each     = { for f in local.level_2 : f.name => f }
  display_name = each.value.name
  parent       = google_folder.l1[each.value.parent].id
}

resource "google_folder" "l3" {
  for_each     = { for f in local.level_3 : f.name => f }
  display_name = each.value.name
  parent       = google_folder.l2[each.value.parent].id
}

resource "google_folder" "l4" {
  for_each     = { for f in local.level_4 : f.name => f }
  display_name = each.value.name
  parent       = google_folder.l3[each.value.parent].id
}

# Combine all folder IDs so Projects can find them easily
locals {
  all_folders = merge(
    { for k, v in google_folder.l1 : v.display_name => v.name },
    { for k, v in google_folder.l2 : v.display_name => v.name },
    { for k, v in google_folder.l3 : v.display_name => v.name },
    { for k, v in google_folder.l4 : v.display_name => v.name }
  )
}

# --- 2. PROJECTS ---

resource "google_project" "main" {
  for_each = { for p in var.projects : p.project_id => p }

  name            = each.value.project_name
  project_id      = each.value.project_id
  billing_account = var.billing_account
  
  # Look up the folder ID from the local map
  folder_id       = local.all_folders[each.value.parent_folder]
}

# --- 3. ENABLE API ---

resource "google_project_service" "compute" {
  for_each = google_project.main

  project = each.value.project_id
  service = "compute.googleapis.com"
  
  disable_on_destroy = false
}

# --- 4. WAIT TIMER (The solution to your question) ---
# This pauses Terraform for 60 seconds after enabling the API
resource "time_sleep" "wait_for_api" {
  create_duration = "60s"

  depends_on = [google_project_service.compute]
}

# --- 5. VM INSTANCES ---

module "compute_instances" {
  source = "./modules/compute_instance"

  for_each = { for vm in var.instances : vm.name => vm }

  instance_name = each.value.name
  project_id    = each.value.target_project_id
  zone          = each.value.zone
  machine_type  = each.value.machine_type
  image         = each.value.image
  disk_size     = each.value.disk_size
  disk_type     = each.value.disk_type

  # Explicit dependency on the TIMER, not just the API
  depends_on = [
    time_sleep.wait_for_api
  ]
}