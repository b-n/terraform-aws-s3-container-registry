output "cloudfront_distribution" {
  value = aws_cloudfront_distribution.container_registry
}

output "container_registry_bucket" {
  value = aws_s3_bucket.container_registry
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.container_registry.domain_name
}
