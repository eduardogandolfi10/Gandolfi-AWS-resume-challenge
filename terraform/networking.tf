resource "aws_route53_zone" "zone" {
  comment           = "HostedZone created by Route53 Registrar"
  delegation_set_id = null
  force_destroy     = null
  name              = var.root-domain-bucket-name
  tags              = {}
  tags_all          = {}
}



resource "aws_route53_record" "resume" {
  zone_id = aws_route53_zone.zone.id
  name    = ""
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront-dist.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "resume_test" {
  zone_id = aws_route53_zone.zone.id
  name    = var.subdomain-bucket-name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.test-cloudfront-dist.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = true
  }
}

resource "aws_cloudfront_distribution" "cloudfront-dist" {
  aliases             = [var.root-domain-bucket-name]
  comment             = null
  default_root_object = null
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  tags                = {}
  tags_all            = {}
  wait_for_deployment = true
  web_acl_id          = null
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    default_ttl                = 0
    field_level_encryption_id  = null
    max_ttl                    = 0
    min_ttl                    = 0
    origin_request_policy_id   = null
    realtime_log_config_arn    = null
    response_headers_policy_id = null
    smooth_streaming           = false
    target_origin_id           = aws_s3_bucket.domain-bucket.bucket_regional_domain_name
    trusted_key_groups         = []
    trusted_signers            = []
    viewer_protocol_policy     = "redirect-to-https"
  }
  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = aws_s3_bucket.domain-bucket.bucket_regional_domain_name
    origin_access_control_id = null
    origin_id                = aws_s3_bucket.domain-bucket.bucket_regional_domain_name
    origin_path              = null
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }
  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:${var.aws-account-id}:certificate/${var.certificate-id}"
    cloudfront_default_certificate = false
    iam_certificate_id             = null
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "test-cloudfront-dist" {
  aliases             = [var.subdomain-bucket-name]
  comment             = null
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  tags                = {}
  tags_all            = {}
  wait_for_deployment = true
  web_acl_id          = null
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    default_ttl                = 0
    field_level_encryption_id  = null
    max_ttl                    = 0
    min_ttl                    = 0
    origin_request_policy_id   = null
    realtime_log_config_arn    = null
    response_headers_policy_id = null
    smooth_streaming           = false
    target_origin_id           = aws_s3_bucket.subdomain-bucket.bucket_regional_domain_name
    trusted_key_groups         = []
    trusted_signers            = []
    viewer_protocol_policy     = "redirect-to-https"
  }
  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = aws_s3_bucket.domain-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.web-control.id
    origin_id                = aws_s3_bucket.domain-bucket.bucket_regional_domain_name
    origin_path              = null

  }
  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:${var.aws-account-id}:certificate/${var.certificate-id}"
    cloudfront_default_certificate = false
    iam_certificate_id             = null
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "web-control" {
  description                       = "Control setting for cloudfront Resume Website Access Control"
  name                              = aws_s3_bucket.domain-bucket.bucket_regional_domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_route53_record" "cert-cname" {
  zone_id = aws_route53_zone.zone.id
  name    = var.route-53-cname
  type    = "CNAME"
  ttl = 300
  records = [
  var.route-53-cname
  ]
}

data "aws_cloudfront_cache_policy" "CachingDisabled" {
  name = "CachingDisabled"
}
