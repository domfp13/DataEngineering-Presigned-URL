// Creating an S3 bucket the the name using the variable bucket_name_api
resource "aws_s3_bucket" "de_presigned_api_json_payload" {
  bucket = var.bucket_name_api

  tags = {
    // Getting the name of the bucket from the variable and added to the table of tags
    Owner = "Enrique Plata"
    Team  = "Data Engineering Team - DW"
  }
}
