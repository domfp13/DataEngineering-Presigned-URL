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

# Define the name of the S3 bucket as a variable
variable "bucket_name_api" {
  description = "The name of the S3 bucket used to store the API json payloads"
  type        = string
}
