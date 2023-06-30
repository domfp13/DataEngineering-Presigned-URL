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
  function_name = "DE_PRESIGNED_URL_LAMBDA"

  # Using "Image" since we are using a container image from ECR,
  package_type = "Image"

  # Adding the role so lambda can upload files to the S3 AWS S3 bucket
  role = aws_iam_role.de_presigned_url_lambda_s3_role.arn

  # Timeout in seconds
  timeout = 30

  # Memory size in MB
  memory_size = 128

  # Description of the Lambda function
  description = "Retrieves a PRESIGNED URL of a private S3 bucket, so http post can upload files."

  # Reference the ECR repository and specify the image tag for Lambda's container image
  image_uri = "${aws_ecr_repository.de_presigned_url_ecr.repository_url}:latest"

  # CloudWatch log group
  publish = true

  # Set environment variables for the Lambda function
  environment {
    variables = {
      UploadBucket  = var.bucket_name                        # S3 bucket name
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
    allow_headers = ["*"]                                # Allow all headers
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"] # Allow specified methods
    allow_origins = ["*"]                                # Allow all origins
  }
}

# Creating a Stage so the API Gateway can use the log Grouping for CloudWatch
resource "aws_apigatewayv2_stage" "de_presigned_url_api_gateway_stage" {
  api_id = aws_apigatewayv2_api.de_presigned_url_api_gateway.id
  name   = "de_presigned_url_api_gateway_stage"

  # Setting the logging level to "INFO" is useful if you want to capture details of all requests, regardless of whether they are successful or not. 
  default_route_settings {
    logging_level = "INFO"
  }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.de_presigned_url_api_gateway_log_group.arn
    format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId"
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
}

# Define a route in API Gateway to handle HTTP requests
resource "aws_apigatewayv2_route" "de_presigned_url_api_route_qc" {
  # Specify the ID of the API for this route
  api_id    = aws_apigatewayv2_api.de_presigned_url_api_gateway.id
  route_key = "ANY /qc" # Example route key, modify as needed

  # Link this route to the integration
  target = "integrations/${aws_apigatewayv2_integration.de_presigned_url_api_gateway_lambda_integration.id}"
}

# Define a route in API Gateway to handle HTTP requests
resource "aws_apigatewayv2_route" "de_presigned_url_api_route_prod" {
  # Specify the ID of the API for this route
  api_id    = aws_apigatewayv2_api.de_presigned_url_api_gateway.id
  route_key = "ANY /prod" # Example route key, modify as needed

  # Link this route to the integration
  target = "integrations/${aws_apigatewayv2_integration.de_presigned_url_api_gateway_lambda_integration.id}"
}
