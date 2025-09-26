variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources in"
  default     = "ap-northeast-1"
}

variable "s3_bucket_prefix" {
  type        = string
  description = "Name of the S3 bucket to store Zeek logs"
  default     = "zeek-logs-bucket-poc"
}

variable "s3_bucket_athena_results_prefix" {
  type        = string
  description = "Name of the S3 bucket to store Athena query results"
  default     = "athena-query-results-bucket-poc"
}

variable "athena_workgroup_name" {
  type        = string
  description = "Name of the athena workgroup"
  default     = "athena-workgroup-poc"
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
  default     = "zeek-log-lambda-poc"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.13"
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
  default     = "index.lambda_handler"
}

variable "source_path" {
  description = "Path to Lambda source code directory"
  type        = string
  default     = "./src"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}


