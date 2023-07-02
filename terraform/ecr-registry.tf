# Define the AWS ECR Repository resource.
resource "aws_ecr_repository" "de_presigned_url_ecr" {
  # Name of the ECR repository. This is passed as a variable.
  name = var.repository_name

  # Image tag mutability setting. Set to IMMUTABLE to ensure that image tags cannot be overwritten.
  image_tag_mutability = "MUTABLE"

  # Force delete the repository even if it contains images
  force_delete = true

  # Configure image scanning. 
  image_scanning_configuration {
    # Enable image scanning on push, this ensures images are scanned on being pushed to the repository.
    scan_on_push = true
  }
}
