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

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.storage.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_access.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution for containers stored in s3"
  default_root_object = "index"

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
