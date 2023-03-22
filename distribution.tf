locals {
  s3_origin_id = "s3_storage_container_origin"
}

resource "aws_cloudfront_origin_access_control" "s3_access" {
  name                              = "s3_origin_access_control"
  description                       = "S3 origin access control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "default_cache_policy" {
  name        = "default_cache_policy"
  min_ttl     = 0
  default_ttl = 30
  max_ttl     = 60

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

resource "aws_s3_bucket" "cloudfront_access_logs" {
  bucket = "${var.project}-cloudfront-access-logs"
}

resource "aws_cloudfront_function" "storage_viewer_request" {
  name    = "storage_viewer_request"
  runtime = "cloudfront-js-1.0"
  comment = "Rewriting client requests"
  publish = true
  code    = file("./storage_viewer_request.js")
}

resource "aws_cloudfront_function" "storage_viewer_response" {
  name    = "storage_viewer_response"
  runtime = "cloudfront-js-1.0"
  comment = "Applies Docker ETag header"
  publish = true
  code    = file("./storage_viewer_response.js")
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.storage.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_access.id
    origin_id                = local.s3_origin_id
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Distribution for containers stored in s3"

  logging_config {
    bucket          = aws_s3_bucket.cloudfront_access_logs.bucket_domain_name
    include_cookies = false
  }

  # This should match the value in storage_viewer_request.js
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    target_origin_id = local.s3_origin_id

    cache_policy_id = aws_cloudfront_cache_policy.default_cache_policy.id

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    compress    = true

    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.storage_viewer_request.arn
    }

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.storage_viewer_response.arn
    }
  }

  price_class = "PriceClass_100"

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
