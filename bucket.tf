resource "aws_s3_bucket" "aws-reposync" {
  acl = "private"
  # since all of this data can be easily recreated, 
  # we want to delete it in case we're removing the application itself
  force_destroy = true
  versioning {
    enabled = false
  }
  website {
    index_document = "index.html"
  }

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "aws-reposync" {
  bucket = aws_s3_bucket.aws-reposync.id

  block_public_acls       = true
  block_public_policy     = false
  restrict_public_buckets = true
  ignore_public_acls      = true

}

resource "aws_s3_bucket_object" "index_html" {
  bucket   = aws_s3_bucket.aws-reposync.id
  key      = "index.html"
  source   = "${path.module}/index.html"

  etag = filemd5("${path.module}/index.html")
}


# Upload the repo files to s3://{bucket}/etc/yum.repos.d
resource "aws_s3_bucket_object" "repo_file" {
  for_each = fileset("${var.repos_path}", "*")
  bucket   = aws_s3_bucket.aws-reposync.id
  key      = "etc/yum.repos.d/${each.value}"
  source   = "${var.repos_path}/${each.value}"

  etag = filemd5("${var.repos_path}/${each.value}")
}
