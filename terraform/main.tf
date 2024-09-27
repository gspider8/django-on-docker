# --- main ---
module "s3_storage" {
  source = "./s3_storage"
  project_name = var.project_name
  bucket_name = "learn-django-rds-ecr"
}

module "web_server" {
  source = "./web_server"
  aws_key_name = "dev_key"
  eip_public_ip = var.eip_public_ip
  project_name = var.project_name
  my_ip = var.my_ip
}