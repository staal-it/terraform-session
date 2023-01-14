variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "key_vault_role_assignments" {
  type = map(string)
}
