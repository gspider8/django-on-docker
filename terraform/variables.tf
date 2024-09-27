# --- variables ---
variable "project_name" {
  type    = string
  default = "learn-django-docker-rds-ecr"
}

variable "my_ip" {
  type      = string
  sensitive = true
}

variable "eip_public_ip" {
  type = string
}