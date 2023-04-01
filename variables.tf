variable "project" {
  description = "Name of this project (used to name the cloudfront distribution)"
  nullable    = false
  type        = string
}

// It is very likely that this won't work in other regions.
variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
  type        = string
}

variable "bucket_name" {
  description = "The name of the s3 bucket (globally unique)"
  nullable    = false
  type        = string
}

variable "cloudfront_price_class" {
  description = "The price class to use for cloudfront"
  default     = "PriceClass_100"
  type        = string
}
