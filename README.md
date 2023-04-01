# Terraform S3 Container Registry

Inspiration from https://httptoolkit.com/blog/docker-image-registry-facade/

A statically hosted container registry that matches the is compliant to the
[docker registry v2 API](https://docs.docker.com/registry/spec/api/).

## Purpose

`docker pull registry/image:tag` doesn't do anything particularly special when
pulling images. In fact, there are a couple of quirks when using the docker cli
at least. Failure to specify a `registry` will default the registry to the one
provided by Docker Hub, which will subsequently require you to login.

What if we could host our own registry instead of relying on Docker's free good
will? Well, that is what this terraform module is for.

This terraform module will:

- Create a AWS s3 bucket to store your container images in.
- Put a CloudFront distribution in front of it.
- Put some CloudFront CloudFunctions in place to modify the request and response
  to retrieve and return a resource that `docker` CLI can understand.
- Create a s3 bucket for access logs to help in diagnosing any access problems.

## Outputs

- `cloudfront_distribution` - the terraformed CloudFront distribution (for
  modifying any related settings)
- `contianer_registry_bucket` - the terraformed bucket where the container blobs
  and manifests are stored
- `cloudfront_distribution_domain_name` - the domain name of the distribution
  for easy checking after deployment

## What this module does not do

This module does **not** help you with uploading blobs and manifests, and does
**not** support `docker push`. See the [upload container
example](./example-upload-container/README.md) for inspiration.

## Example usage of this module

See the [example](./example/README.md) for an example of using this module.
