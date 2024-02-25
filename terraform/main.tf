
resource "aws_s3_bucket" "subdomain-bucket" {
  # (resource arguments)
  bucket = var.subdomain-bucket-name
  tags = {
    environment = var.environment-tag
  }
  force_destroy = true
}

resource "aws_s3_bucket" "domain-bucket" {
  # (resource arguments)
  bucket = var.root-domain-bucket-name
  tags = {
    environment = var.environment-tag
  }
  website {
        redirect_all_requests_to = "https://${var.subdomain-bucket-name}"
    }
}




resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.domain-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "PolicyForcloudfrontPrivateContent"{
    bucket = var.subdomain-bucket-name
    policy = jsonencode(
        {
    "Version": "2008-10-17",
    "Id": "PolicyForcloudfrontPrivateContent",
    "Statement": [
        {
            "Sid": "AllowcloudfrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.subdomain-bucket-name}/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": aws_cloudfront_distribution.test-cloudfront-dist.arn
                }
            }
        }
    ]
}
    )
}