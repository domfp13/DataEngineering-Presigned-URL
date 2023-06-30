# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "de_presigned_url_lambda_log_group" {
  name = "/aws/lambda/de_presigned_url_lambda_log_group"
  # retain logs for 7 days
  retention_in_days = 7
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "de_presigned_url_api_gateway_log_group" {
  name = "/aws/api-gateway/de_presigned_url_api_gateway_log_group"
  # retain logs for 7 days
  retention_in_days = 7
}
