output "bucket_name" {
  value       = aws_s3_bucket.state.id
  description = "Terraform state bucket name."
}

output "bucket_arn" {
  value       = aws_s3_bucket.state.arn
  description = "Terraform state bucket ARN."
}

output "bucket_region" {
  value       = aws_s3_bucket.state.bucket_region
  description = "Region of the Terraform state bucket."
}
