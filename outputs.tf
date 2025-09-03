output "created_folders" {
  description = "A map of all created folders and their IDs (numeric)."
  value       = local.all_folder_ids
}

output "created_projects" {
  description = "A map of all created projects and their numeric project numbers."
  value       = { for key, project in google_project.main : key => project.number }
}
