variable "org_id" {
  description = "The ID of the GCP Organization."
  type        = string
}

variable "billing_account" {
  description = "The Billing Account ID."
  type        = string
}

variable "folders" {
  description = "A flat list of all folders to create, with their parent explicitly defined."
  type = list(object({
    name   = string
    parent = string # The 'name' of the parent folder, or 'org' for the root.
  }))
  default = []
}

variable "projects" {
  description = "A list of projects to create, including the name of their parent folder."
  type = list(object({
    parent_folder = string # The 'name' of the parent folder.
    project_name  = string
    project_id    = string
  }))
  default = []
}
