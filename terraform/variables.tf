# Define the variable used for the repository name.
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

# Define the name of the S3 bucket as a variable
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

# Define the name of the SNS topic as a variable
variable "topic_name" {
  description = "The name of the SNS topic"
  type        = string
}

# Define the email endpoint for the SNS topic subscription as a variable
variable "endpoint_email" {
  description = "The email endpoint for the SNS topic subscription"
  type        = string
}
