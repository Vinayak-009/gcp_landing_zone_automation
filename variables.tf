variable "org_id" {
  description = "The ID of the GCP Organization."
  type        = string
}

variable "billing_account" {
  description = "The Billing Account ID."
  type        = string
}

variable "folders" {
  description = "A hierarchical definition of folders and their projects."
  type        = any
  default     = []
}
