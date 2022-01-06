output "bucket_id" {
  value = aws_s3_bucket.aws-reposync.id
}

output "website_endpoint" {
  value = aws_s3_bucket.aws-reposync.website_endpoint
}
