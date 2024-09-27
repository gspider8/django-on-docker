# -- outputs --
output "s3_bucket_info" {
  value = "${module.s3_storage.bucket-name} Access: ${module.s3_storage.django_access_key}, Secret"
}

output "web_server_info" {
  value = "${var.eip_public_ip} - ${module.web_server.local_key_name}"
}