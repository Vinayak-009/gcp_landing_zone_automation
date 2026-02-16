variable "org_id" {
  type        = string
  description = "Organization ID (passed via secrets)"
}

variable "billing_account" {
  type        = string
  description = "Billing Account ID (passed via secrets)"
}

variable "folders" {
  description = "List of folders from JSON."
  type = list(object({
    name   = string
    parent = string
  }))
  default = []
}

variable "projects" {
  description = "List of projects from JSON."
  type = list(object({
    parent_folder = string
    project_name  = string
    project_id    = string
  }))
  default = []
}

variable "instances" {
  description = "List of instances from JSON."
  type = list(object({
    name              = string
    target_project_id = string
    region            = string
    zone              = string
    machine_type      = string
    disk_size         = number
    disk_type         = string
    image             = string
  }))
  default = []
}