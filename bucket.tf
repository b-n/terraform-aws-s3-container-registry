resource "aws_s3_bucket" "storage" {
  bucket = "${var.project}-container-storage"
}

resource "aws_s3_bucket_public_access_block" "block_all" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "storage_acl" {
  bucket = aws_s3_bucket.storage.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.storage.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront.json
}

data "aws_iam_policy_document" "allow_access_from_cloudfront" {
  statement {
    sid    = "AllowCloudFrontReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.storage.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

// Create an empty resource at /v2/ which returns a 200. This tricks docker
// into thinking a repository exists here.
resource "aws_s3_object" "index" {
  bucket  = aws_s3_bucket.storage.id
  key     = "v2/index.html"
  content = ""

  metadata = {
    docker-distribution-api-version = "registry/2.0"
  }
}

