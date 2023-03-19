variable "project" {
  description = "Name of this project"
  default     = "s3-docker-registry"
  type        = string
}

variable "region" {
  description = "AWS Region"
  default     = "eu-central-1"
  type        = string
}
