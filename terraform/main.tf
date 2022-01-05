# Deploys aws-reposync and puts all of the repo config files in S3
#
# 
# author: @danielpodwysocki (https://gitlab.com/danielpodwysocki)
# date: 2022-01



# A dictionary containing tags that will be applied to all resources from this module
variable "tags" {

}

# A list of subnet ids that the compute environment for this module can use
# They must be subnets with access to internet
variable "subnets" {

}
variable "region" {
  default = "eu-central-1"
}

# Path to a folder containing all of the repo files to be uploaded to /etc/yum.repos.d
variable "repos_path" {

}

variable "vpc" {

}

resource "aws_ecs_cluster" "aws-reposync" {
  name               = "aws-reposync"
  capacity_providers = ["FARGATE"]
  tags               = var.tags
}

resource "aws_ecs_task_definition" "aws-reposync" {
  family                   = "aws-reposync"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.allow_aws-reposync.arn
  task_role_arn            = aws_iam_role.allow_aws-reposync.arn
  tags                     = var.tags

  container_definitions = jsonencode([
    {
      name      = "aws-reposync"
      image     = "registry.gitlab.com/danielpodwysocki/aws-reposync"
      cpu       = 512
      memory    = 1024
      essential = true
      environment = [
        { "name" : "target_bucket", "value" : "s3://${aws_s3_bucket.aws-reposync.id}" }
      ]
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "${aws_cloudwatch_log_group.aws-reposync.name}",
          "awslogs-region" : "${var.region}",
          "awslogs-stream-prefix" : "aws-reposync"
        }
      }
    }
  ])
}



resource "aws_s3_bucket" "aws-reposync" {
  acl = "private"
  # since all of this data can be easily recreated, 
  # we want to delete it in case we're removing the application itself
  force_destroy = true
  versioning {
    enabled = false
  }
  website {

  }

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "aws-reposync" {
  bucket = aws_s3_bucket.aws-reposync.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true

}



resource "aws_iam_role" "allow_aws-reposync" {
  name               = "allow_aws-reposync"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  inline_policy {
    name   = "allow_aws-reposync"
    policy = data.aws_iam_policy_document.allow_aws-reposync.json

  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
  tags = var.tags
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]

    }
    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "allow_aws-reposync" {
  statement {

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.aws-reposync.arn,
      "${aws_s3_bucket.aws-reposync.arn}/*",
    ]
  }
}

resource "aws_cloudwatch_log_group" "aws-reposync" {
  name = "aws-reposync"

  tags = var.tags
}


# Upload the repo files to s3://{bucket}/etc/yum.repos.d
resource "aws_s3_bucket_object" "repo_file" {
  for_each = fileset("${var.repos_path}", "*")
  bucket   = aws_s3_bucket.aws-reposync.id
  key      = "etc/yum.repos.d/${each.value}"
  source   = "${var.repos_path}/${each.value}"

  etag = filemd5("${var.repos_path}/${each.value}")
}
