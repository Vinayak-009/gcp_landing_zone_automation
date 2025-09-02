# main.tf

# Root-level folders
resource "google_folder" "main" {
  for_each = {
    "fldr-shared" = "organizations/${var.org_id}"
    "fldr-srb"    = "organizations/${var.org_id}"
  }

  display_name = each.key
  parent       = each.value
}

# Subfolders under fldr-srb
resource "google_folder" "srb_sub" {
  for_each = {
    "fldr-srb-nov" = google_folder.main["fldr-srb"].name
  }

  display_name = each.key
  parent       = each.value
}

# Sub-subfolders under fldr-srb-nov
resource "google_folder" "srb_nov_sub" {
  for_each = {
    "fldr-srb-nov-bel" = google_folder.srb_sub["fldr-srb-nov"].name
  }

  display_name = each.key
  parent       = each.value
}

# Final leaf subfolders under fldr-srb-nov-bel
resource "google_folder" "srb_nov_bel_sub" {
  for_each = {
    "fldr-srb-nov-bel-hr"  = google_folder.srb_nov_sub["fldr-srb-nov-bel"].name
    "fldr-srb-nov-bel-fin" = google_folder.srb_nov_sub["fldr-srb-nov-bel"].name
  }

  display_name = each.key
  parent       = each.value
}
