output "created_folders" {
  description = "A map of created folders, keyed by their full path, with their IDs as values."
  value = {
    for key, folder in google_folder.main :
    key => folder.id
  }
}

output "created_projects" {
  description = "A map of created projects, keyed by their project ID, with their numeric project numbers as values."
  value = {
    for key, project in google_project.main :
    key => project.number
  }
}
