# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "de_presigned_url_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.de_presigned_url_lambda.function_name}"
  retention_in_days = 7

  tags = {
    Owner = "Enrique Plata"
    Team  = "Data Engineering Team - DW"
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "de_presigned_url_api_gateway_log_group" {
  name              = "/aws/api-gateway/${aws_apigatewayv2_api.de_presigned_url_api_gateway.name}"
  retention_in_days = 7
  tags = {
    Owner = "Enrique Plata"
    Team  = "Data Engineering Team - DW"
  }

}
