// The bucket where the containers will be stored
resource "aws_s3_bucket" "container_registry" {
  bucket = try(var.bucket_name, "${var.project}-container-storage")
}

// Ensure public access is restricted. Access is provided through a cloudfront distribution
resource "aws_s3_bucket_public_access_block" "block_all" {
  bucket = aws_s3_bucket.container_registry.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "storage_acl" {
  bucket = aws_s3_bucket.container_registry.id
  acl    = "private"
}

// Docker clients use this to identify the presence of a registry, and act based on the returned
// HTTP status code:
// - 200 - docker clients should continue with retrieval.
// - 401 - a login request is sent to the returned Location header.
// Using the default object (index.html) in `/v2/` will create a 200 response.
resource "aws_s3_object" "index" {
  bucket  = aws_s3_bucket.container_registry.id
  key     = "v2/index.html"
  content = ""

  metadata = {
    docker-distribution-api-version = "registry/2.0"
  }
}

