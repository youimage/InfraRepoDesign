# S3 Configuration for Shared Infrastructure
# Object storage and static content hosting

# Random suffix for globally unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# S3 Bucket for application assets
resource "aws_s3_bucket" "app_assets" {
  bucket = "${var.project_name}-${var.environment}-app-assets-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-assets"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "application-assets"
  }
}

# S3 Bucket for application logs
resource "aws_s3_bucket" "app_logs" {
  bucket = "${var.project_name}-${var.environment}-app-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-logs"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "application-logs"
  }
}

# S3 Bucket for Terraform state (backend)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-${var.environment}-terraform-state-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-${var.environment}-terraform-state"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "terraform-backend"
  }
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "app_logs" {
  bucket = aws_s3_bucket.app_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_logs" {
  bucket = aws_s3_bucket.app_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "app_logs" {
  bucket = aws_s3_bucket.app_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration for logs
resource "aws_s3_bucket_lifecycle_configuration" "app_logs" {
  bucket = aws_s3_bucket.app_logs.id

  rule {
    id     = "log_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# IAM policy for ECS tasks to access S3
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-${var.environment}-s3-access"
  description = "Policy for ECS tasks to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_assets.arn,
          "${aws_s3_bucket.app_assets.arn}/*",
          aws_s3_bucket.app_logs.arn,
          "${aws_s3_bucket.app_logs.arn}/*"
        ]
      }
    ]
  })
}

# Attach S3 policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_s3_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# CloudFront distribution for static assets (optional)
resource "aws_cloudfront_distribution" "app_assets" {
  origin {
    domain_name = aws_s3_bucket.app_assets.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.app_assets.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.app_assets.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.app_assets.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cdn"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "app_assets" {
  comment = "Origin Access Identity for ${var.project_name}-${var.environment}"
}

# S3 bucket policy for CloudFront
resource "aws_s3_bucket_policy" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.app_assets.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.app_assets.arn}/*"
      }
    ]
  })
}

# Outputs
output "s3_app_assets_bucket" {
  description = "S3 bucket name for application assets"
  value       = aws_s3_bucket.app_assets.id
}

output "s3_app_logs_bucket" {
  description = "S3 bucket name for application logs"
  value       = aws_s3_bucket.app_logs.id
}

output "cloudfront_distribution_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.app_assets.domain_name
}