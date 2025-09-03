output "created_folders" {
  description = "A map of all created folders and their IDs."
  value       = { for key, folder in google_folder.main : key => folder.id }
}

output "created_projects" {
  description = "A map of all created projects and their numeric project numbers."
  value       = { for key, project in google_project.main : key => project.number }
}
