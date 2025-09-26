module "glue_crawler_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.59.0"

  trusted_role_services = [
    "glue.amazonaws.com"
  ]

  trusted_role_actions = [
    "sts:AssumeRole"
  ]

  trust_policy_conditions = [
    {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  ]

  create_role       = true
  role_requires_mfa = false

  role_name_prefix = "AWSGlueServiceRole-"

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]

  inline_policy_statements = [
    {
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      effect    = "Allow"
      resources = ["${module.s3_bucket.s3_bucket_arn}/*"]
      conditions = [{
        test     = "StringEquals"
        variable = "aws:ResourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }]
    }
  ]
}

resource "aws_glue_catalog_database" "zeek_db" {
  name = "zeek-logs-db"
}

resource "aws_glue_crawler" "zeek_crawler" {
  name = "zeek-logs-crawler"
  role = module.glue_crawler_role.iam_role_arn
  database_name = aws_glue_catalog_database.zeek_db.name

  s3_target {
    path = "s3://${module.s3_bucket.s3_bucket_id}"
  }

  schedule = null
}

resource "aws_glue_workflow" "zeek_workflow" {
  name = "zeek-logs-workflow"
}

resource "aws_glue_trigger" "zeek_trigger" {
  workflow_name = aws_glue_workflow.zeek_workflow.name
  name          = "zeek-logs-trigger"
  type          = "EVENT"

  actions {
    crawler_name = aws_glue_crawler.zeek_crawler.name
  }
}