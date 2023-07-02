terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.50.0"
    }
  }
}

# Specify the provider and region. AWS is used in this example.
provider "aws" {
  region = "us-east-1"
}

# Create a Lambda Function
resource "aws_lambda_function" "de_presigned_url_lambda" {
  # Name of the Lambda function
  function_name = "de_presigned_url_lambda"

  # Using "Image" since we are using a container image from ECR,
  package_type = "Image"

  # Adding the role so lambda can upload files to the S3 AWS S3 bucket
  role = aws_iam_role.de_presigned_url_lambda_s3_role.arn

  # Timeout in seconds
  timeout = 30

  # Memory size in MB
  memory_size = 128

  # Description of the Lambda function
  description = "Retrieves a PRESIGNED URL of a private S3 bucket, so and HTTPS POST can upload files directly to S3 bucket."

  # Reference the ECR repository and specify the image tag for Lambda's container image
  image_uri = "${aws_ecr_repository.de_presigned_url_ecr.repository_url}:v2"

  # CloudWatch log group
  publish = true

  # Set environment variables for the Lambda function, this are available as environment variables in the Lambda function
  environment {
    variables = {
      BUCKET_NAME  = var.bucket_name                        # S3 bucket name
      SNS_TOPIC_ARN = aws_sns_topic.de_presigned_url_sns.arn # SNS Topic ARN
    }
  }
}

# Create an HTTP API Gateway
resource "aws_apigatewayv2_api" "de_presigned_url_api_gateway" {
  # Name of the API
  name = "de_presigned_url_api_gateway"

  # Protocol type for the API
  protocol_type = "HTTP"

  # CORS configuration for the API
  cors_configuration {
    allow_headers = ["*"]   # Allow file-name HEADERS
    allow_methods = ["GET"] # Allow specified methods
    allow_origins = ["*"]   # Allow all origins
  }
}

# Define the integration between API Gateway and Lambda
resource "aws_apigatewayv2_integration" "de_presigned_url_api_gateway_lambda_integration" {
  # Specify the ID of the API to integrate with
  api_id = aws_apigatewayv2_api.de_presigned_url_api_gateway.id

  # Specify the integration type (AWS_PROXY for Lambda proxy integration)
  integration_type = "AWS_PROXY"

  # Specify the ARN of the Lambda function
  integration_uri = aws_lambda_function.de_presigned_url_lambda.invoke_arn

  # Specify the ARN of the IAM Role for API Gateway
  credentials_arn = aws_iam_role.de_presigned_url_api_gateway_role.arn

  # HTTP method that the integration (in this case, the API Gateway) should use when forwarding the request to the backend service (in this case, the Lambda function)
  integration_method = "POST"
}

# Define a route in API Gateway to handle HTTP requests
resource "aws_apigatewayv2_route" "de_presigned_url_api_route" {
  # Specify the ID of the API for this route
  api_id    = aws_apigatewayv2_api.de_presigned_url_api_gateway.id
  route_key = "GET /files" # specifies the HTTP method and resource path that the client (browser, mobile app, etc.) should use when calling the API Gateway.

  # Link this route to the integration
  target = "integrations/${aws_apigatewayv2_integration.de_presigned_url_api_gateway_lambda_integration.id}"
}

# Deploy the API. This takes a snapshot of the API configuration and deploys it.
resource "aws_apigatewayv2_deployment" "de_presigned_url_api_deployment" {
  api_id = aws_apigatewayv2_api.de_presigned_url_api_gateway.id # ID of the API Gateway
  # triggers attribute redeploy the API whenever the route configuration changes
  triggers = {
    redeployment = sha1(jsonencode(aws_apigatewayv2_route.de_presigned_url_api_route))
  }
  # This ensures that the deployment is dependent on the route configuration
  depends_on = [aws_apigatewayv2_route.de_presigned_url_api_route]
}

# Creating a Stage for the QC env
resource "aws_apigatewayv2_stage" "de_presigned_url_api_gateway_stage_qc" {
  api_id = aws_apigatewayv2_api.de_presigned_url_api_gateway.id
  name   = "de_presigned_url_api_gateway_stage_qc"
  # deployment_id = aws_apigatewayv2_deployment.de_presigned_url_api_deployment.id # The deployment to associate with this stage
  auto_deploy = true # Auto deploy when there are changes

  # Adding logging so the API Gateway can use the log Grouping for CloudWatch
  # Setting the logging level to "INFO" is useful if you want to capture details of all requests, regardless of whether they are successful or not. 
  default_route_settings {
    logging_level = "INFO"

    # Define throttling
    # Rate limit: This is the number of requests that are allowed per second. For example, if the rate limit is set to 100, then up to 100 requests can be sent to your API each second.
    # Burst limit (or concurrency limit): This is the maximum number of requests that can be sent to your API at the same time. This is helpful for accommodating spikes in traffic. For example, if the burst limit is 200, your API can handle 200 requests all at once, but then the rate limit will dictate how many requests per second can continue to be made.
    throttling_burst_limit = 20
    throttling_rate_limit  = 5
  }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.de_presigned_url_api_gateway_log_group.arn
    format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
}

# Creating a Stage for the QC env
resource "aws_apigatewayv2_stage" "de_presigned_url_api_gateway_stage_prod" {
  api_id = aws_apigatewayv2_api.de_presigned_url_api_gateway.id
  name   = "de_presigned_url_api_gateway_stage_prod"
  # deployment_id = aws_apigatewayv2_deployment.de_presigned_url_api_deployment.id # The deployment to associate with this stage
  auto_deploy = true # Auto deploy when there are changes

  # Adding logging so the API Gateway can use the log Grouping for CloudWatch
  # Setting the logging level to "INFO" is useful if you want to capture details of all requests, regardless of whether they are successful or not. 
  default_route_settings {
    logging_level = "INFO"

    # Define throttling
    # Rate limit: This is the number of requests that are allowed per second. For example, if the rate limit is set to 100, then up to 100 requests can be sent to your API each second.
    # Burst limit (or concurrency limit): This is the maximum number of requests that can be sent to your API at the same time. This is helpful for accommodating spikes in traffic. For example, if the burst limit is 200, your API can handle 200 requests all at once, but then the rate limit will dictate how many requests per second can continue to be made.
    throttling_burst_limit = 20
    throttling_rate_limit  = 5
  }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.de_presigned_url_api_gateway_log_group.arn
    format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
}
