# --- s3_storage.main ---

# -- s3 --
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Environment = "Dev"
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_get_access" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.allow_public_get_access.json
}

# https://www.youtube.com/watch?v=JQVQcNN0cXE
# open to everyone or else pages won't load on the web
data "aws_iam_policy_document" "allow_public_get_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.main.arn}/*",
    ]
  }
}

# -- iam --
resource "aws_iam_user" "django" {
  name = var.project_name
  path = "/users/"

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_access_key" "django" {
  user = aws_iam_user.django.name
}

resource "aws_iam_user_policy" "django" {
  name   = "django-storages-permission-${var.project_name}"
  user   = aws_iam_user.django.name
  policy = data.aws_iam_policy_document.django_user.json
}

data "aws_iam_policy_document" "django_user" {
  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions"
    ]
    resources = [
      aws_s3_bucket.main.arn
    ]
  }
  statement {
    sid    = "2"
    effect = "Allow"
    actions = [
      "s3:*Object*",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      "${aws_s3_bucket.main.arn}/*"
    ]
  }
}
