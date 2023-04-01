# Container registry example

This folder contains an example of using this container registry terraform
module to host your own container registry in an s3 bucket.

## Required Modifications

S3 bucket names are globally unique for AWS. Change `bucket_name` in `main.tf`
to something globally unique.

```hcl
  bucket_name = "my-shiny-globally-unique-s3-bucket-name"
```

It's also advisory to give your `project` a name that is identifiable to you.

## Deploying

Install required dependencies:

```sh
$ terraform init
```

Generate the plan to see what will be deployed.

```sh
$ terraform plan
```

👆 Check to ensure the output is what you want

Follow the prompts to completion:

```sh
$ terraform apply
```

The cloudfront distribution domain name should be now available for you to use.
