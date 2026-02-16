output "created_folders" {
  description = "A map of all created folders and their resource names (folders/id)."
  # Changed from local.all_folder_ids to local.all_folders
  value       = local.all_folders
}

output "created_projects" {
  description = "A map of all created projects and their numeric project numbers."
  value       = { for key, project in google_project.main : key => project.number }
}

output "vm_instances" {
  description = "Details of the created VM instances."
  value       = module.compute_instances
}
