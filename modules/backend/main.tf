# S3 Backend Resources
resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project}-tfs"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "${var.project}-tfs"
    Project = "${var.project}"
  }
}

resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_bucket_encryption" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Add bucket policy for state management
resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::916600710645:user/terraform"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.tfstate.arn
        Condition = {
          StringEquals = {
            "s3:prefix" = "${aws_s3_bucket.tfstate.id}/terraform.tfstate"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::916600710645:user/terraform"
        }
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.tfstate.arn}/terraform.tfstate"]
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::916600710645:user/terraform"
        }
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.tfstate.arn}/terraform.tfstate.tflock"]
      },
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "local_file" "key" {
#   filename = "backend.tf"
#   content  = <<EOF
# terraform {
#   backend "s3" {
#     bucket         = "${aws_s3_bucket.tfstate.id}"
#     key            = "terraform.tfstate"
#     region         = "${var.region}"
#     encrypt        = true
#     use_lockfile   = true
#   }
# }
#   EOF
# }