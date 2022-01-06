# aws-reposync [work-in-progress]

A container designed to sync RPM repositories to a bucket, from where they can be made accessible to your offline EC2 instances.
The container is based on the official `amazonlinux` image.

## Deployment

This application is deployed via Terraform, an example deployment looks like this:
```
module "aws-reposync" {
  source  = "danielpodwysocki/reposync/aws"
  version = "0.0.2"

  # a list of subnet IDs where the sync can be executed
  subnets = [aws_subnet.dev-public-c.id]
  tags = {
    "Name" = "aws-reposync"
    "Env"  = "production"
  }
  repos_path = "/Users/daniel/workspace/aws-reposync/example/repos/"
  vpc_id     = aws_vpc.dev.id
  region     = var.region
  route_table_ids = [
    aws_route_table.default.id,
  ]
  cron = "* 8 * * ? *"
}

```
`subnets` must have internet access via an Internet gateway
`cron` defines how often an ECS task is launched to sync the repos.
`repos_path` is where the .repo files are stored on the machine you are running `terraform apply` from
`route_table_ids` is needed for adding the routes to the S3 gateway endpoint


## General information

This module will deploy an S3 gateway in your private VPC which allows read-only access to the synced repos.
See `outputs` for how you can use it to access your repositories in the private subnets.

## Usage

In order to set up the sync, put all of your repository configurations in one directory.
When deploying the configuration via Terraform, set your
They will end up in /etc/yum.repos.d/ on the container and will be synced to the bucket.

The path in the bucket will look like this: http://ENDPOINT_URL/REPO_ID , where REPO_ID is the ID in the .repo file

## outputs

`website_endpoint` - the URL underneath which you can access the Bucket from within your VPC.
Use this to configure your repostiroy in the private subnets.

`bucket_id` - the ID of the bucket the reposync uses

