locals {
  # Dynamically filter folders by level (handles arbitrary depth up to 10 without code changes)
  level_1_folders = [for f in var.folders : f if f.parent == "org"]
  level_2_folders = [for f in var.folders : f if contains([ff.name for ff in local.level_1_folders], f.parent)]
  level_3_folders = [for f in var.folders : f if contains([ff.name for ff in local.level_2_folders], f.parent)]
  level_4_folders = [for f in var.folders : f if contains([ff.name for ff in local.level_3_folders], f.parent)]
  level_5_folders = [for f in var.folders : f if contains([ff.name for ff in local.level_4_folders], f.parent)]
  level_6_folders = [for f in var.folders : f if contains([ff.name for ff in local.level_5_folders], f.parent)]
  level_7_folders = [for f in var.folders : f if contains([ff.name for ff in local.level_6_folders], f.parent)]
  level_8_folders = [for f in var.folders : f if contains([ff.name for ff in local.level_7_folders], f.parent)]
  level_9_folders = [for f in var.folders : f if contains([ff.name for ff in local.level_8_folders], f.parent)]
  level_10_folders = [for f in var.folders : f if contains([ff.name for ff in local.level_9_folders], f.parent)]

  # Merge all folder IDs for dynamic lookup in projects/outputs (covers all levels)
  all_folder_ids = merge(
    { for k, v in google_folder.level_1 : k => v.id },
    { for k, v in google_folder.level_2 : k => v.id },
    { for k, v in google_folder.level_3 : k => v.id },
    { for k, v in google_folder.level_4 : k => v.id },
    { for k, v in google_folder.level_5 : k => v.id },
    { for k, v in google_folder.level_6 : k => v.id },
    { for k, v in google_folder.level_7 : k => v.id },
    { for k, v in google_folder.level_8 : k => v.id },
    { for k, v in google_folder.level_9 : k => v.id },
    { for k, v in google_folder.level_10 : k => v.id }
  )
}

# Level 1 (root folders under org)
resource "google_folder" "level_1" {
  for_each = { for f in local.level_1_folders : f.name => f }

  display_name = each.value.name
  parent       = "organizations/${var.org_id}"
}

# Level 2
resource "google_folder" "level_2" {
  for_each = { for f in local.level_2_folders : f.name => f }

  display_name = each.value.name
  parent       = google_folder.level_1[each.value.parent].name
}

# Level 3
resource "google_folder" "level_3" {
  for_each = { for f in local.level_3_folders : f.name => f }

  display_name = each.value.name
  parent       = google_folder.level_2[each.value.parent].name
}

# Level 4
resource "google_folder" "level_4" {
  for_each = { for f in local.level_4_folders : f.name => f }

  display_name = each.value.name
  parent       = google_folder.level_3[each.value.parent].name
}

# Level 5
resource "google_folder" "level_5" {
  for_each = { for f in local.level_5_folders : f.name => f }

  display_name = each.value.name
  parent       = google_folder.level_4[each.value.parent].name
}

# Level 6
resource "google_folder" "level_6" {
  for_each = { for f in local.level_6_folders : f.name => f }

  display_name = each.value.name
  parent       = google_folder.level_5[each.value.parent].name
}

# Level 7
resource "google_folder" "level_7" {
  for_each = { for f in local.level_7_folders : f.name => f }

  display_name = each.value.name
  parent       = google_folder.level_6[each.value.parent].name
}

# Level 8
resource "google_folder" "level_8" {
  for_each = { for f in local.level_8_folders : f.name => f }

  display_name = each.value.name
  parent       = google_folder.level_7[each.value.parent].name
}

# Level 9
resource "google_folder" "level_9" {
  for_each = { for f in local.level_9_folders : f.name => f }

  display_name = each.value.name
  parent       = google_folder.level_8[each.value.parent].name
}

# Level 10
resource "google_folder" "level_10" {
  for_each = { for f in local.level_10_folders : f.name => f }

  display_name = each.value.name
  parent       = google_folder.level_9[each.value.parent].name
}

# Projects (use merged IDs for dynamic lookup; fixed invalid .folder_id to .id)
resource "google_project" "main" {
  for_each = { for p in var.projects : p.project_id => p }

  project_id      = each.value.project_id
  name            = each.value.project_name
  billing_account = var.billing_account
  folder_id       = local.all_folder_ids[each.value.parent_folder]
}
