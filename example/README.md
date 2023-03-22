# Example

This example shows how to build and extract the relevant blobs in order to load
these into a privately deployed repository.

## Prerequistes

- `aws` cli installed and logged in
- this repo has been deployed (keep note of the `distribution_domain_name`
  output
- docker-cli and buildx is installed and can build images

## Setting up a docker builder

A docker image is a series of binaries and json files which are generated from
`docker build`. We can utilise a docker buildx to create a builder which enables
us to extract a tar'd image with all necessary files.

Create the docker build context:

```sh
docker buildx create --name docker-container --driver docker-container
```

👆 The name can be whatever you want, just make sure it's used when running
buildx with the `--builder command`

## Build and extract the relevant image parts

Build and extract the image:

```sh
docker buildx build --builder docker-container --output=type=docker,dest=example.tar .
tar -xf example.tar
```

👆 Tagging is unimportant since it's just a file we'll create later.

You should now have the following:
```
example
 |- blobs/sha256/
 |   |- 0b6d1506931e6990ddb6f11a73c8851c6371b798ecd9da91668d84da0f1e559c 
 |   |- 63b65145d645c1250c391b2d16ebe53b3747c295ca8ba2fcb6b0cf064a4dc21c
 |   \- bffe16b6336ccce7a8764375e87bdb18b25b421ce70847f4697161144a58c685 
 |- index.json
 |- manifest.json
 \- oci-layout
```

The 3 sha's in `blobs/sha256/` may differ but they should contain the following:

- The docker manifest file
- The docker configuration file
- The docker image rootfs image (likely the largest)

## Upload the files into the bucket

Create and upload our tag (assuming the lag of `latest` but could be anything)

```sh
$ export manifest_sha="$(jq '.manifests[0].digest' index.json)"
$ touch latest
$ aws s3 cp --metadata docker-content-digest="$manifest_sha",docker-etag="$manifest_sha" latest s3://s3-docker-registry-container-storage/v2/example/manifests/latest
```

Upload the Manifest (sha can be found in the `index.json` file):

```sh
$ export sha="0b6d1506931e6990ddb6f11a73c8851c6371b798ecd9da91668d84da0f1e559c"
$ aws s3 cp \
  --content-type "application/vnd.docker.distribution.manifest.v2+json" \
  --metadata docker-content-digest="sha256:$sha",docker-etag="sha256:$sha" \
  ./blobs/sha256/$hash \
  s3://s3-docker-registry-container-storage/v2/example/blobs/sha256/$sha
```

Upload the container image config (sha is in the manifest file):

```sh
$ export sha="bffe16b6336ccce7a8764375e87bdb18b25b421ce70847f4697161144a58c685"
$ aws s3 cp \
  --content-type "application/vnd.docker.container.image.v1+json" \
  --metadata docker-content-digest="sha256:$sha",docker-etag="sha256:$sha" \
  ./blobs/sha256/$hash \
  s3://s3-docker-registry-container-storage/v2/example/blobs/sha256/$sha
```

Upload the rootfs layer (sha is in the manifest file):

```sh
$ export sha="63b65145d645c1250c391b2d16ebe53b3747c295ca8ba2fcb6b0cf064a4dc21c"
$ aws s3 cp \
  --content-type "application/vnd.docker.image.rootfs.diff.tar.gzip" \
  --metadata docker-content-digest="sha256:$sha",docker-etag="sha256:$sha" \
  ./blobs/sha256/$hash \
  s3://s3-docker-registry-container-storage/v2/example/blobs/sha256/$sha
```

👆 There are of course ways to automate this, but this is the detail of what 
needs to be done in order to upload an image. The `Content-Type` is extremely
important on these requests. If you get the content-type wrong, you will likely
need to invalidate the cache on Cloudfront.

## Pull your image and use it

This is just the same as any normal docker pull - except from your registry:

```sh
$ docker run -it --rm <distribution>.cloudfront.net/example:latest
Hello!
```
