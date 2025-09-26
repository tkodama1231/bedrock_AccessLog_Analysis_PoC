module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.0.1"

  function_name = var.lambda_function_name
  description   = "Zeek log summarization Lambda function"
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime

  source_path = var.source_path

  publish = true

  memory_size = 256
  timeout     = 60

  environment_variables = {
    ATHENA_DB         = aws_glue_catalog_database.zeek_db.name
    ATHENA_TABLE      = replace(module.s3_bucket.s3_bucket_id, "-", "_")
    ATHENA_OUTPUT     = "s3://${module.s3_bucket_athena_results.s3_bucket_id}/athena-results/"
    SLACK_WEBHOOK_URL = var.slack_webhook_url
    BEDROCK_MODEL     = "amazon.nova-lite-v1:0" 
  }

  attach_policy_json = true

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "${module.s3_bucket_athena_results.s3_bucket_arn}/*",
          module.s3_bucket_athena_results.s3_bucket_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetTables"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog",
          aws_glue_catalog_database.zeek_db.arn,
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.zeek_db.name}/*"
        ]
      }
    ]
  })

  tags = {
    Environment = "poc"
    Project     = "AI-LogSummary"
  }
}
