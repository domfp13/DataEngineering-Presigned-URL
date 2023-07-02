# Outpout the URL of the created ECR repository.
output "repository_url" {
  description = "The URL of the created ECR repository"
  value       = aws_ecr_repository.de_presigned_url_ecr.repository_url
}

# Output the ARN of the created ECR repository.
output "repository_arn" {
  description = "The ARN of the created ECR repository"
  value       = aws_ecr_repository.de_presigned_url_ecr.arn
}

# Output the ARN of the Lambda Function
output "lambda_function_arn" {
  description = "Lambda Function ARN"
  value       = aws_lambda_function.de_presigned_url_lambda.arn
}

# Output the API Gateway URL 
output "api_gateway_endpoint_url" {
  description = "The endpoint URL of the API Gateway"
  value       = aws_apigatewayv2_api.de_presigned_url_api_gateway.api_endpoint
}

# Output the ARN of the SNS Topic
output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.de_presigned_url_sns.arn
}
