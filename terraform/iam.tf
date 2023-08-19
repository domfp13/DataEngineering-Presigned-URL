# Creating a role so Lambda can talk to S3
resource "aws_iam_role" "de_presigned_url_lambda_s3_role" {
  name = "de_presigned_url_lambda_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Owner = "Enrique Plata"
    Team  = "Data Engineering Team - DW"
  }
}

# Creating a policy so Lambda can talk to S3
resource "aws_iam_role_policy" "de_presigned_url_lambda_s3_policy" {
  name = "de_presigned_url_lambda_s3_policy"
  role = aws_iam_role.de_presigned_url_lambda_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/*",
          "arn:aws:s3:::${var.bucket_name}"
        ]
      }
    ]
  })
}

// Creating a policy so Lambda can talk to de_presigned_api_json_payload bucket
resource "aws_iam_role_policy" "de_presigned_url_lambda_s3_api_policy" {
  name = "de_presigned_url_lambda_s3_api_policy"
  role = aws_iam_role.de_presigned_url_lambda_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name_api}/*",
          "arn:aws:s3:::${var.bucket_name_api}"
        ]
      }
    ]
  })
}

# Creating a policy so Lambda can log events in CloudWatch Group
resource "aws_iam_role_policy" "de_presigned_url_lambda_lambda_logging_policy" {
  name = "de_presigned_url_lambda_lambda_logging_policy"
  role = aws_iam_role.de_presigned_url_lambda_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Effect   = "Allow",
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

# Creating a role so API Gateway talks to lambda function
resource "aws_iam_role" "de_presigned_url_api_gateway_role" {
  name = "de_presigned_url_api_gateway_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Owner = "Enrique Plata"
    Team  = "Data Engineering Team - DW"
  }
}

# IAM Policy allowing API Gateway to invoke the Lambda function
resource "aws_iam_role_policy" "de_presigned_url_api_gateway_policy" {
  name = "de_presigned_url_api_gateway_policy"
  role = aws_iam_role.de_presigned_url_api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction"
        ],
        Effect   = "Allow",
        Resource = aws_lambda_function.de_presigned_url_lambda.arn
      }
    ]
  })
}

# Creating a policy so API Gateway can Log events in CloudWatch Group
resource "aws_iam_role_policy" "de_presigned_url_api_gateway_logging_policy" {
  name = "de_presigned_url_api_gateway_logging_policy"
  role = aws_iam_role.de_presigned_url_api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Effect   = "Allow",
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

# Creating a user so Local Testing can access the event in CloudWatch de_presigned_url_lambda_log_group group
resource "aws_iam_user" "de_presigned_url_local_env_user" {
  name = "de_presigned_url_local_env_user"
  tags = {
    Owner = "Enrique Plata"
    Team  = "Data Engineering Team - DW"
  }
}

# Creating a policy so Local Testing can access the event in CloudWatch de_presigned_url_lambda_log_group group
resource "aws_iam_user_policy" "de_presigned_url_local_env_user_policy" {
  name = "de_presigned_url_local_env_user_policy"
  user = aws_iam_user.de_presigned_url_local_env_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:GetLogEvents",
          "logs:DescribeLogGroups"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
