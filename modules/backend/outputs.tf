# S3 Backend outputs
output "state_bucket_id" {
  description = "ID of the Terraform state S3 bucket"
  value       = aws_s3_bucket.tfstate.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = aws_s3_bucket.tfstate.arn
}
