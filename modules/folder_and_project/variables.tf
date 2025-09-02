variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "billing_account" {
  description = "GCP Billing Account ID"
  type        = string
}

variable "parent_id" {
  description = "The resource ID of the parent (e.g., 'organizations/123' or 'folders/456')."
  type        = string
}

variable "parent_path" {
  description = "The string path of the parent (e.g., 'fldr-ind')."
  type        = string
}

variable "folders_to_create" {
  description = "The list of folder objects to create at this level."
  type        = any
  default     = []
}