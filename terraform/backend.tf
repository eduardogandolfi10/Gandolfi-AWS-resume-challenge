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