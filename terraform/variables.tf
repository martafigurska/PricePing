variable "project_id" {
  default = "priceping-480812"
}

variable "region" {
  default = "europe-west1"
}

variable "project_number" {
  description = "Numeric GCP project number"
  type        = string
}

variable "gmail_user" {
  description = "Adres Gmail używany do wysylania maili"
  type        = string
}

variable "gmail_app_password" {
  description = "App Password dla Gmail"
  type        = string
  sensitive   = true
}