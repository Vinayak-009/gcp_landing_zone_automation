variable "org_id" {
  description = "The ID of the GCP Organization."
  type        = string
}

variable "billing_account" {
  description = "The Billing Account ID."
  type        = string
}

variable "folder_paths" {
  description = "A simple list of all desired folder paths. e.g., ['level1/level2', 'level1/another']"
  type        = set(string)
  default     = []
}

variable "projects" {
  description = "A list of projects to create, including their full parent folder path."
  type = list(object({
    folder_path  = string
    project_name = string
    project_id   = string
  }))
  default = []
}
