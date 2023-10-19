provider "aws" {
  region = "us-east-2" # Change this to your desired AWS region
 }

resource "aws_lambda_function" "my_lambda_function" {
  function_name = "pawel-serverless-app-lambda"
  handler      = "index.handler"
  runtime      = "python3.11"
  filename     = "C:/Terraform/terraform-serverless-project/serverless/python/lambda_code.zip"  # Replace with the correct path

  role = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.my_s3_bucket.bucket
    }
  }

}

resource "aws_lambda_event_source_mapping" "sqs_trigger"{
    event_source_arn = aws_sqs_queue.sqs_queue.arn
    function_name = aws_lambda_function.my_lambda_function.arn
}

resource "aws_s3_bucket" "my_s3_bucket" {
  bucket = "pawel-serverless-app-s3-bucket"
}

resource "aws_sqs_queue" "sqs_queue"{
    
  name                      = "pawel-serverless-app-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}


resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  policy_arn = aws_iam_policy.lambda_access_policy.arn
  role       = aws_iam_role.lambda_exec_role.name
}

resource "aws_iam_policy" "lambda_access_policy" {
  name        = "s3_access_policy"
  description = "Policy allowing access to the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ],
        Effect   = "Allow",
        Resource = [
          aws_s3_bucket.my_s3_bucket.arn,
          "${aws_s3_bucket.my_s3_bucket.arn}/*",
        ],
      },
      {
        Action = [
          "lambda:InvokeFunction"
        ]
        Effect = "Allow",
        Resource = "*"
        
      },
      {
        Effect = "Allow",
        Action = [
            "sqs:*"
        ],
        Resource = [
            aws_sqs_queue.sqs_queue.arn
        ]
      }
    ],
  })
}