# Create an SNS Topic
resource "aws_sns_topic" "de_presigned_url_sns" {
  # Name of the SNS Topic
  name = var.topic_name
}

# Create a subscription for the SNS Topic
resource "aws_sns_topic_subscription" "de_presigned_url_sns_subscription" {
  # ARN of the SNS Topic
  topic_arn = aws_sns_topic.de_presigned_url_sns.arn

  # Protocol for the subscription (in this case, email)
  protocol = "email"

  # Endpoint for the subscription (in this case, an email address)
  endpoint = var.endpoint_email
}
