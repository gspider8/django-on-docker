# --- s3_storage.outputs ---
output "django_access_key" {
  value = aws_iam_access_key.django.id
}

output "django_secret_access_key" {
  value     = aws_iam_access_key.django.secret
  sensitive = true
}

output "bucket-name" {
  value = aws_s3_bucket.main.bucket
}