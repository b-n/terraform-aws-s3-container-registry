// This id is used the same time in one resource
locals {
  container_registry_origin_id = "container_registry_origin"
}

// Set cloudfront access control into the container registry bucket
resource "aws_cloudfront_origin_access_control" "container_registry" {
  name                              = "${var.project}_origin_access_control"
  description                       = "${var.project} origin access control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "registry_default_cache_policy" {
  name        = "${var.project}_default_cache_policy"
  min_ttl     = 0
  default_ttl = 3600
  max_ttl     = 86400

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

// Configure the container registry access logs to store in an s3 bucket
resource "aws_s3_bucket" "registry_access_logs" {
  bucket = "${aws_s3_bucket.container_registry.bucket}-access-logs"
}

// Create cloudfront functions which will modify request and response headers 
resource "aws_cloudfront_function" "registry_viewer_request" {
  name    = "${var.project}_registry_viewer_request"
  runtime = "cloudfront-js-1.0"
  comment = "Rewriting client requests"
  publish = true
  code    = file("${path.module}/js/container_registry_viewer_request.js")
}

resource "aws_cloudfront_function" "registry_viewer_response" {
  name    = "${var.project}_registry_viewer_response"
  runtime = "cloudfront-js-1.0"
  comment = "Applying headers from metadata"
  publish = true
  code    = file("${path.module}/js/container_registry_viewer_response.js")
}

// The main cloudfront distribution for access to the container registry
resource "aws_cloudfront_distribution" "container_registry" {
  origin {
    domain_name              = aws_s3_bucket.container_registry.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.container_registry.id
    origin_id                = local.container_registry_origin_id
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project} distribution for container registry"

  logging_config {
    bucket          = aws_s3_bucket.registry_access_logs.bucket_domain_name
    include_cookies = false
  }

  # This should match the value in storage_viewer_request.js
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    target_origin_id = local.container_registry_origin_id

    cache_policy_id = aws_cloudfront_cache_policy.registry_default_cache_policy.id

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
    compress    = true

    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.registry_viewer_request.arn
    }

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.registry_viewer_response.arn
    }
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

// S3 Bucket IAM Policy to allow cloudfront access to the bucket. This is applied to the container
// registry bucket.
data "aws_iam_policy_document" "registry_cloudfront_access" {
  statement {
    sid    = "AllowCloudFrontReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.container_registry.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.container_registry.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "registry_cloudfront_access" {
  bucket = aws_s3_bucket.container_registry.id
  policy = data.aws_iam_policy_document.registry_cloudfront_access.json
}
