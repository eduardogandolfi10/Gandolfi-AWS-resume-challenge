
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

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = var.dynamodb-name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Name"

  attribute {
    name = "Name"
    type = "S"
  }

  attribute {
    name = "view_count"
    type = "N"
  }

  tags = {
    Name        = "terraform-table"
    Environment = var.environment-tag
  }

resource "aws_lambda_function" "viewer_count" {
  filename      = data.archive_file.zip.output_path
  source_code_hash  = data.archive_file.zip.output_base64sha256
  function_name   = "view-count-update-new"
  role        = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "view-count-update-iam-role"
  
  assume_role_policy = jsonencode(
{
  "Version": "2012-10-17"
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
)
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name = "aws_iam_policy_for_terraform_resume_project"
  path = "/"
  description = "AWS IAM Policy for managing view-count-update"
  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": "logs:CreateLogGroup",
          "Resource": "arn:aws:logs:us-east-1:*:*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": [
            "arn:aws:logs:us-east-1:${var.aws-account-id}:log-group:/aws/lambda/view-count-update-new:*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "dynamodb:BatchGetItem",
            "dynamodb:GetItem",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:BatchWriteItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"
          ],
          "Resource": "arn:aws:dynamodb:us-east-1:${var.aws-account-id}:table/resume-challenge-db"
        }
      ]
    }
  )
}

resource "aws_iam_policy_attachment" "attach_iam_policy_to_iam_role" {
  name = "resume_lambda_IAM_Policy_attachment"
  roles = [aws_iam_role.iam_for_lambda.name]
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip" {
  type = "zip"
  source_dir = "${path.module}/lambda/"
  output_path = "${path.module}/packagedlambda.zip"
}

resource "aws_api_gateway_rest_api" "resume-challenge-new" {
  name = var.api-gateway-name
}

resource "aws_api_gateway_resource" "update-view-count" {
  parent_id   = aws_api_gateway_rest_api.resume-challenge-new.root_resource_id
  path_part   = "update-view-count"
  rest_api_id = aws_api_gateway_rest_api.resume-challenge-new.id
}

resource "aws_api_gateway_method" "get-method" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.update-view-count.id
  rest_api_id   = aws_api_gateway_rest_api.resume-challenge-new.id
  request_parameters = {
    "method.request.querystring.name" = true
  }
}

resource "aws_api_gateway_integration" "integration-settings" {
  http_method = aws_api_gateway_method.get-method.http_method
  resource_id = aws_api_gateway_resource.update-view-count.id
  rest_api_id = aws_api_gateway_rest_api.resume-challenge-new.id
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_parameters = {
    "integration.request.querystring.name" = "method.request.querystring.name"
  }
   request_templates = {
    "application/json" = jsonencode(
{
"body-json" : $input.json('$'),
"params" : {
#foreach($type in $allParams.keySet())
    #set($params = $allParams.get($type))
"$type" : {
    #foreach($paramName in $params.keySet())
    "$paramName" : "$util.escapeJavaScript($params.get($paramName))"
        #if($foreach.hasNext),#end
    #end
}
    #if($foreach.hasNext),#end
#end
},
"stage-variables" : {
#foreach($key in $stageVariables.keySet())
"$key" : "$util.escapeJavaScript($stageVariables.get($key))"
    #if($foreach.hasNext),#end
#end
},
"context" : {
    "account-id" : "$context.identity.accountId",
    "api-id" : "$context.apiId",
    "api-key" : "$context.identity.apiKey",
    "authorizer-principal-id" : "$context.authorizer.principalId",
    "caller" : "$context.identity.caller",
    "cognito-authentication-provider" : "$context.identity.cognitoAuthenticationProvider",
    "cognito-authentication-type" : "$context.identity.cognitoAuthenticationType",
    "cognito-identity-id" : "$context.identity.cognitoIdentityId",
    "cognito-identity-pool-id" : "$context.identity.cognitoIdentityPoolId",
    "http-method" : "$context.httpMethod",
    "stage" : "$context.stage",
    "source-ip" : "$context.identity.sourceIp",
    "user" : "$context.identity.user",
    "user-agent" : "$context.identity.userAgent",
    "user-arn" : "$context.identity.userArn",
    "request-id" : "$context.requestId",
    "resource-id" : "$context.resourceId",
    "resource-path" : "$context.resourcePath"
    }
})
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.resume-challenge-new.id
  resource_id = aws_api_gateway_resource.update-view-count.id
  http_method = aws_api_gateway_method.get-method.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = false
  "method.response.header.Access-Control-Allow-Methods"     = false
  "method.response.header.Access-Control-Allow-Origin"     = false
  }
}

resource "aws_api_gateway_integration_response" "view-count-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.resume-challenge-new.id
  resource_id = aws_api_gateway_resource.update-view-count.id
  http_method = aws_api_gateway_method.get-method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  "method.response.header.Access-Control-Allow-Methods"     = "'*'"
  "method.response.header.Access-Control-Allow-Origin"     = "'*'"
  }
}

resource "aws_api_gateway_deployment" "update-view-count-deploy" {
  rest_api_id = aws_api_gateway_rest_api.resume-challenge-new.id

  triggers = {

    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.update-view-count.id,
      aws_api_gateway_method.get-method.id,
      aws_api_gateway_integration.integration-settings.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "sandbox-stage" {
  deployment_id = aws_api_gateway_deployment.update-view-count-deploy.id
  rest_api_id   = aws_api_gateway_rest_api.resume-challenge-new.id
  stage_name    = "sandbox"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.viewer_count.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.resume-challenge-new.execution_arn}/*/*"
}


resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = var.dynamodb-name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Name"

  attribute {
    name = "Name"
    type = "S"
  }

  attribute {
    name = "view_count"
    type = "N"
  }

  tags = {
    Name        = "terraform-table"
    Environment = "dev"
  }
}