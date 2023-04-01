// Note: It is very likely this only works in us-east-1
variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      managed_by = "terraform"
    }
  }
}

module "container_registry" {
  source = "../"

  project = "my-container-registry"

  region      = var.region
  bucket_name = "my-container-registry"
}

output "cloudfront_distribution_domain_name" {
  value = module.container_registry.cloudfront_distribution_domain_name
}
